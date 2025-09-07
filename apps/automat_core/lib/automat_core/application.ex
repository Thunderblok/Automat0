defmodule AutomatCore.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("AutomatCore started")
    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
