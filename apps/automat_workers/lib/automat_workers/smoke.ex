defmodule AutomatWorkers.Smoke do
  @moduledoc false
  require Logger

  def run_trial() do
    Application.ensure_all_started(:automat_metrics)
    Logger.info("Running trial-smoke...")
    :ok = AutomatWorkers.PyTrial.run_once()
    Logger.info("trial-smoke complete")
  end
end
