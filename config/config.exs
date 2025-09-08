# Global config for Automat umbrella
import Config

config :logger, level: :info

config :automat_ui, AutomatUI.Endpoint,
	url: [host: "localhost"],
	http: [ip: {0,0,0,0,0,0,0,0}, port: 4000],
	secret_key_base: String.duplicate("a", 64),
	render_errors: [accepts: ~w(html json)],
	pubsub_server: AutomatUI.PubSub

config :phoenix, :json_library, Jason

# Bus adapter: :in_memory (default), AutomatBus.MQTT, AutomatBus.ZMQ
adapter_env = System.get_env("AUTOMAT_BUS_ADAPTER", "in_memory")
adapter_mod = case String.downcase(adapter_env) do
	"mqtt" -> AutomatBus.MQTT
	"zmq" -> AutomatBus.ZMQ
	_ -> AutomatBus.InMemory
end
config :automat_bus, adapter: adapter_mod

# MQTT defaults (only used when adapter is AutomatBus.MQTT)
config :automat_bus, :mqtt,
	enabled: false,
	host: System.get_env("MQTT_HOST", "localhost"),
	port: String.to_integer(System.get_env("MQTT_PORT", "1883")),
	client_id: System.get_env("MQTT_CLIENT_ID", "automat-dev"),
	qos: String.to_integer(System.get_env("MQTT_QOS", "0")),
	subscriptions: [System.get_env("MQTT_SUBS", "automat/#")],
	keep_alive: 30
