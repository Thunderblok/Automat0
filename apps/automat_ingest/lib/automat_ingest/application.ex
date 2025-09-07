defmodule AutomatIngest.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = []
    Logger.info("AutomatIngest started")
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
