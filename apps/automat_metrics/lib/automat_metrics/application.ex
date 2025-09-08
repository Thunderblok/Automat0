defmodule AutomatMetrics.Application do
  use Application
  require Logger

  @impl true
  def start(_t,_a) do
    children = [AutomatMetrics.Store]
    Logger.info("AutomatMetrics started")
    Supervisor.start_link(children, strategy: :one_for_one, name: AutomatMetrics.Supervisor)
  end
end
