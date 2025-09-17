defmodule AutomatUI.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AutomatUI.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser
    live "/", AutomatUI.Live.Home
  end

  scope "/experiments", AutomatUI do
    pipe_through :api
    post "/run", ExperimentController, :run
    get "/status", ExperimentController, :status
  end
end
