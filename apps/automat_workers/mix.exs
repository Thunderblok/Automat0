defmodule AutomatWorkers.MixProject do
  use Mix.Project

  def project do
    [
      app: :automat_workers,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AutomatWorkers.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:venomous, "~> 0.3"},
      {:automat_bus, in_umbrella: true},
      {:automat_metrics, in_umbrella: true},
      {:telemetry, "~> 1.2"}
    ]
  end
end
