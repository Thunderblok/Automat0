defmodule AutomatUI.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: AutomatUI.Finch},
      AutomatUI.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AutomatUI.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
