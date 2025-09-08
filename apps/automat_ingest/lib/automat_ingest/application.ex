defmodule AutomatIngest.Application do
  use Application
  require Logger

  @impl true
  def start(_t, _a) do
    children = []
    Logger.info("AutomatIngest started")
    Supervisor.start_link(children, strategy: :one_for_one, name: AutomatIngest.Supervisor)
  end
end
