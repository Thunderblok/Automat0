defmodule AutomatBus do
  @moduledoc """
  Simple in-memory bus facade using Phoenix.PubSub with minimal topic helpers.
  """
  alias Phoenix.PubSub

  @pubsub AutomatBus.PubSub

  @doc """
  Publish a message on a topic via PubSub.
  """
  def publish(topic, message), do: PubSub.broadcast(@pubsub, topic, message)

  @doc """
  Compute topic names used by the system.

  Supported kinds:
  - :heartbeats -> "automat.heartbeats.<trial_id>"
  - :events     -> "automat.events.<trial_id>"
  - {:promotion, study_id} -> "automat.promotion.<study_id>"
  """
  def topic(:heartbeats, trial_id) when is_binary(trial_id), do: "automat.heartbeats." <> trial_id
  def topic(:events, trial_id) when is_binary(trial_id), do: "automat.events." <> trial_id
  def topic({:promotion, study_id}) when is_binary(study_id), do: "automat.promotion." <> study_id
end
defmodule AutomatBus.Adapter do
  @moduledoc """
  Behaviour for pluggable bus adapters (in-memory | mqtt | zeromq | nats).
  """
  @callback subscribe(topic :: String.t()) :: any()
  @callback unsubscribe(topic :: String.t()) :: any()
  @callback publish(topic :: String.t(), message :: term()) :: any()
end

defmodule AutomatBus.InMemory do
  @moduledoc """
  Phoenix.PubSub-backed in-memory adapter.
  """
  @pubsub AutomatBus.PubSub
  @behaviour AutomatBus.Adapter
  @impl true
  def subscribe(topic), do: Phoenix.PubSub.subscribe(@pubsub, topic)
  @impl true
  def unsubscribe(topic), do: Phoenix.PubSub.unsubscribe(@pubsub, topic)
  @impl true
  def publish(topic, message), do: Phoenix.PubSub.broadcast(@pubsub, topic, message)
end

defmodule AutomatBus do
  @moduledoc """
  Bus facade delegating to configured adapter.
  Topics:
    - "automat.heartbeats." <> trial_id
    - "automat.events." <> trial_id
  """

  defp adapter, do: Application.get_env(:automat_bus, :adapter, AutomatBus.InMemory)

  def subscribe(topic), do: adapter().subscribe(topic)
  def unsubscribe(topic), do: adapter().unsubscribe(topic)
  def publish(topic, message), do: adapter().publish(topic, message)

  def topic(:heartbeats, trial_id), do: "automat.heartbeats." <> to_string(trial_id)
  def topic(:events, trial_id), do: "automat.events." <> to_string(trial_id)
  def topic(:control, trial_id), do: "automat.control." <> to_string(trial_id)
  def topic(:study_events, study_id), do: "automat.study." <> to_string(study_id)
end

defmodule AutomatBus.MQTT do
  @moduledoc """
  MQTT adapter using Tortoise311.
  - Publishes payloads to MQTT (JSON) and also to local PubSub for in-process consumers.
  - Subscribes (via wildcard from config) and forwards incoming MQTT messages into PubSub.
  - Connection is supervised by AutomatBus.Application when adapter is set to AutomatBus.MQTT and enabled.
  """
  @behaviour AutomatBus.Adapter
  require Logger
  alias __MODULE__.Conn

  @impl true
  def subscribe(topic), do: Phoenix.PubSub.subscribe(AutomatBus.PubSub, topic)

  @impl true
  def unsubscribe(topic), do: Phoenix.PubSub.unsubscribe(AutomatBus.PubSub, topic)

  @impl true
  def publish(topic, message) do
    # Always broadcast locally for in-process consumers
    Phoenix.PubSub.broadcast(AutomatBus.PubSub, topic, message)
    # Also publish to the broker (best-effort)
    payload = encode!(message)
    client_id = client_id()
    qos = mqtt_qos()
    retain = false
    case Tortoise311.publish(client_id, topic, payload, qos: qos, retain: retain) do
      :ok -> :ok
      {:error, reason} ->
        Logger.warning("MQTT publish failed: #{inspect(reason)} topic=#{topic}")
        :ok
    end
  end

  defp encode!(message) do
    case message do
      bin when is_binary(bin) -> bin
      _ -> Jason.encode!(message)
    end
  end

  defp client_id do
    Application.get_env(:automat_bus, :mqtt, []) |> Keyword.get(:client_id, Conn.default_client_id())
  end

  defp mqtt_qos do
    case Application.get_env(:automat_bus, :mqtt, []) |> Keyword.get(:qos, 0) do
      0 -> :at_most_once
      1 -> :at_least_once
      2 -> :exactly_once
      _ -> :at_most_once
    end
  end
end

defmodule AutomatBus.MQTT.Conn do
  @moduledoc false
  use Supervisor
  require Logger

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def default_client_id do
    host = :inet.gethostname() |> elem(1) |> to_string()
    "automat-" <> host
  end

  @impl true
  def init(:ok) do
    cfg = Application.get_env(:automat_bus, :mqtt, [])
    enabled = Keyword.get(cfg, :enabled, false)
    if enabled do
      client_id = Keyword.get(cfg, :client_id, default_client_id())
      host = Keyword.get(cfg, :host, "localhost") |> to_charlist()
      port = Keyword.get(cfg, :port, 1883)
      subscriptions = Keyword.get(cfg, :subscriptions, ["automat/#"]) |> Enum.map(&{&1, mqtt_qos(cfg)})

      handler = {AutomatBus.MQTT.Handler, []}

      conn_child = %{
        id: Tortoise311.Connection,
        start: {
          Tortoise311.Connection,
          :start_link,
          [
            client_id: client_id,
            server: {Tortoise311.Transport.Tcp, host: host, port: port},
            handler: handler,
            subscriptions: subscriptions,
            keep_alive: Keyword.get(cfg, :keep_alive, 30)
          ]
        }
      }

      Logger.info("Starting MQTT client #{client_id} -> #{to_string(host)}:#{port} subscriptions=#{inspect(subscriptions)}")
      Supervisor.init([conn_child], strategy: :one_for_one)
    else
      Logger.info("MQTT disabled; not starting client")
      Supervisor.init([], strategy: :one_for_one)
    end
  end

  defp mqtt_qos(cfg) do
    case Keyword.get(cfg, :qos, 0) do
      0 -> :at_most_once
      1 -> :at_least_once
      2 -> :exactly_once
      _ -> :at_most_once
    end
  end
end

defmodule AutomatBus.MQTT.Handler do
  @moduledoc false
  @behaviour Tortoise311.Handler
  require Logger

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @impl true
  def connection(status, state) do
    Logger.info("MQTT connection: #{inspect(status)}")
    {:ok, state}
  end

  @impl true
  def handle_message(topic, payload, state) do
    message = decode(payload)
    Phoenix.PubSub.broadcast(AutomatBus.PubSub, topic, message)
    {:ok, state}
  end

  defp decode(bin) do
    case Jason.decode(bin) do
      {:ok, data} -> data
      _ -> bin
    end
  end

  @impl true
  def subscription(status, topic_filter, state) do
    Logger.info("MQTT subscription #{inspect(status)} for #{inspect(topic_filter)}")
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state), do: :ok
end

defmodule AutomatBus.ZMQ do
  @moduledoc """
  ZeroMQ adapter (stub): currently delegates to in-memory PubSub.
  TODO: Implement real PUSH/PULL + PUB/SUB bridge using :chumak.
  """
  @behaviour AutomatBus.Adapter
  def subscribe(topic), do: AutomatBus.InMemory.subscribe(topic)
  def unsubscribe(topic), do: AutomatBus.InMemory.unsubscribe(topic)
  def publish(topic, message), do: AutomatBus.InMemory.publish(topic, message)
end
