defmodule AutomatBus.Application do
  use Application
  require Logger

  @impl true
  def start(_t,_a) do
    Logger.info("AutomatBus started")
    children =
      [
        {Phoenix.PubSub, name: AutomatBus.PubSub}
      ] ++ mqtt_children()
    Supervisor.start_link(children, strategy: :one_for_one, name: AutomatBus.Supervisor)
  end

  defp mqtt_children do
    case Application.get_env(:automat_bus, :adapter, AutomatBus.InMemory) do
      AutomatBus.MQTT -> [{AutomatBus.MQTT.Conn, []}]
      _ -> []
    end
  end
end
