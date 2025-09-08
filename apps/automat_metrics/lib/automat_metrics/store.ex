defmodule AutomatMetrics.Store do
  @moduledoc """
  Simple in-memory store + JSONL sink and optional MLflow client (future).
  """
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def ingest(trial_id, event), do: GenServer.cast(__MODULE__, {:ingest, trial_id, event})

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_cast({:ingest, trial, event}, state) do
    # append to local JSONL under _artifacts
    root = Path.expand("_artifacts", File.cwd!())
    File.mkdir_p!(root)
    File.write!(Path.join(root, "events.jsonl"), Jason.encode!(Map.put(event, :trial_id, trial)) <> "\n", [:append])
    {:noreply, Map.update(state, trial, [event], &[event | &1])}
  end

  def snapshot(), do: GenServer.call(__MODULE__, :snapshot)
  @impl true
  def handle_call(:snapshot, _from, state), do: {:reply, state, state}
end

# public re-export
defmodule AutomatMetrics do
  defdelegate ingest(trial_id, event), to: AutomatMetrics.Store
  defdelegate snapshot(), to: AutomatMetrics.Store
end
