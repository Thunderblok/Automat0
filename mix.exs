# Umbrella project for Automat

# mix.exs must be at root, but in umbrella we have mix.exs + apps/*/mix.exs
# We'll generate a minimal umbrella by delegating to Mix.Umbrella

# Create a tiny umbrella config
# Note: phx server cmd in Dockerfile assumes a Phoenix app; we provide a minimal endpoint later.

defmodule Automat.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    []
  end
end
