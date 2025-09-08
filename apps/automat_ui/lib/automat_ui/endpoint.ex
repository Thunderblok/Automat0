defmodule AutomatUI.Endpoint do
  use Phoenix.Endpoint, otp_app: :automat_ui

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Static, at: "/", from: :automat_ui, gzip: false
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], json_decoder: Phoenix.json_library()
  plug Plug.MethodOverride
  plug Plug.Head
  plug AutomatUI.Router
end
