import Config

config :automat_ui, AutomatUI.Endpoint,
  url: [host: "localhost"],
  http: [ip: {0,0,0,0,0,0,0,0}, port: 4000],
  secret_key_base: String.duplicate("a", 64),
  render_errors: [accepts: ~w(html json)],
  pubsub_server: AutomatUI.PubSub

config :phoenix, :json_library, Jason
