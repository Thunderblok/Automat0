defmodule AutomatCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :automat_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {AutomatCore.Application, []}]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.4"}
    ]
  end
end
