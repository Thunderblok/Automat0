defmodule AutomatUI.ExperimentController do
  use Phoenix.Controller, formats: [:json]

  alias AutomatUI.K8s

  def run(conn, params) do
    ns = System.get_env("NAMESPACE", "cerebros")
    exp = Map.get(params, "experiment_name", "cerebros-nlp-poc")
    max_len = Map.get(params, "max_len", 1536)
    epochs = Map.get(params, "epochs", 1)
    batch = Map.get(params, "batch", 8)
    grad_accum = Map.get(params, "grad_accum", 5)

    suffix = :erlang.unique_integer([:positive]) |> Integer.to_string()

    prep_name = "cerebros-prepare-tokens-" <> suffix
    train_name = "cerebros-train-" <> suffix

    with :ok <- K8s.create_prepare_job(ns, prep_name, max_len),
         :ok <- K8s.wait_job_complete(ns, prep_name, 900),
         :ok <- K8s.create_train_job(ns, train_name, epochs, batch, grad_accum) do
      json(conn, %{
        status: "submitted",
        jobs: %{prepare: prep_name, train: train_name},
        mlflow_ui: "http://mlflow-service:5000",
        experiment_name: exp
      })
    else
      {:error, reason} -> conn |> put_status(500) |> json(%{error: inspect(reason)})
    end
  end

  def status(conn, params) do
    ns = System.get_env("NAMESPACE", "cerebros")
    prep = Map.get(params, "prepare")
    train = Map.get(params, "train")
    prep_s = if prep, do: AutomatUI.K8s.job_status(ns, prep), else: nil
    train_s = if train, do: AutomatUI.K8s.job_status(ns, train), else: nil
    json(conn, %{
      prepare: prep_s,
      train: train_s
    })
  end
end
