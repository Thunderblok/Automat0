defmodule AutomatUI.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AutomatUI.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AutomatUI.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
