defmodule AutomatCore.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Placeholder for future Chief/Scheduler
      AutomatCore.TrialSupervisor
    ]

    opts = [strategy: :one_for_one, name: AutomatCore.Supervisor]
    Logger.info("AutomatCore started")
    Supervisor.start_link(children, opts)
  end
end
