defmodule AutomatIngest.MixProject do
  use Mix.Project

  def project do
    [
      app: :automat_ingest,
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
    [extra_applications: [:logger], mod: {AutomatIngest.Application, []}]
  end

  defp deps do
    [
      {:nx, "~> 0.10"},
      {:tokenizers, "~> 0.5"}
    ]
  end
end
