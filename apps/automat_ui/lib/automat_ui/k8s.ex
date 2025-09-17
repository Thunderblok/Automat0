defmodule AutomatUI.K8s do
  @moduledoc false

  @service_host System.get_env("KUBERNETES_SERVICE_HOST", "kubernetes.default.svc")
  @service_port System.get_env("KUBERNETES_SERVICE_PORT", "443")
  @token_path "/var/run/secrets/kubernetes.io/serviceaccount/token"
  @ca_path "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

  def create_prepare_job(ns, name, max_len) do
    body = %{
      apiVersion: "batch/v1",
      kind: "Job",
      metadata: %{name: name, labels: %{app: "cerebros", phase: "prepare"}},
      spec: %{
        backoffLimit: 2,
        ttlSecondsAfterFinished: 600,
        template: %{
          spec: %{
            restartPolicy: "Never",
            containers: [
              %{
                name: "prepare",
                image: "ghcr.io/thunderblok/cerebros-runner:pi",
                command: ["python", "tokenize_first_runner.py"],
                args: ["--mode", "prepare", "--output", "/data/train_tokens.npz", "--max_len", to_string(max_len), "--tokenizer_checkpoint", "HuggingFaceTB/SmolLM3-3B"],
                env: [
                  %{name: "MLFLOW_TRACKING_URI", value: "http://mlflow-service:5000"}
                ],
                volumeMounts: [%{name: "data", mountPath: "/data"}],
                resources: %{
                  requests: %{cpu: "1", memory: "4Gi"},
                  limits: %{cpu: "2", memory: "8Gi"}
                }
              }
            ],
            volumes: [%{name: "data", persistentVolumeClaim: %{claimName: "cerebros-data-pvc"}}]
          }
        }
      }
    }

    post_job(ns, body)
  end

  def create_train_job(ns, name, epochs, batch, grad_accum) do
    body = %{
      apiVersion: "batch/v1",
      kind: "Job",
      metadata: %{name: name, labels: %{app: "cerebros", phase: "train"}},
      spec: %{
        backoffLimit: 2,
        ttlSecondsAfterFinished: 600,
        template: %{
          spec: %{
            restartPolicy: "Never",
            containers: [
              %{
                name: "train",
                image: "ghcr.io/thunderblok/cerebros-runner:pi",
                command: ["python", "tokenize_first_runner.py"],
                args: [
                  "--mode", "train",
                  "--cache", "/data/train_tokens.npz",
                  "--epochs", to_string(epochs),
                  "--batch", to_string(batch),
                  "--grad_accum", to_string(grad_accum),
                  "--print-sample"
                ],
                env: [%{name: "MLFLOW_TRACKING_URI", value: "http://mlflow-service:5000"}],
                volumeMounts: [%{name: "data", mountPath: "/data"}],
                resources: %{
                  requests: %{cpu: "1", memory: "4Gi"},
                  limits: %{cpu: "2", memory: "8Gi"}
                }
              }
            ],
            volumes: [%{name: "data", persistentVolumeClaim: %{claimName: "cerebros-data-pvc"}}]
          }
        }
      }
    }

    post_job(ns, body)
  end

  def job_status(ns, name) do
    with {:ok, %Finch.Response{status: 200, body: body}} <- get("/apis/batch/v1/namespaces/#{ns}/jobs/#{name}") do
      j = Jason.decode!(body)
      %{ "status" => status } = j
      phase = cond do
        (status["succeeded"] || 0) > 0 -> "Complete"
        (status["failed"] || 0) > 0 -> "Failed"
        true -> "Running"
      end
      %{
        phase: phase,
        startedAt: get_in(status, ["startTime"]) || "",
        finishedAt: get_in(status, ["completionTime"]) || ""
      }
    else
      {:ok, %Finch.Response{status: s}} -> %{phase: "Unknown", code: s}
      {:error, e} -> %{phase: "Error", error: inspect(e)}
    end
  end

  def wait_job_complete(ns, name, timeout_sec) do
    deadline = System.monotonic_time(:second) + timeout_sec
    do_wait(ns, name, deadline)
  end

  defp do_wait(ns, name, deadline) do
    if System.monotonic_time(:second) > deadline do
      {:error, :timeout}
    else
      case job_status(ns, name) do
        %{phase: "Complete"} -> :ok
        %{phase: "Failed"} -> {:error, :failed}
        _ -> :timer.sleep(2_000); do_wait(ns, name, deadline)
      end
    end
  end

  defp post_job(ns, body) do
    path = "/apis/batch/v1/namespaces/#{ns}/jobs"
    headers = default_headers()
    json = Jason.encode!(body)
    req = Finch.build(:post, base_url() <> path, headers, json)
    case Finch.request(req, AutomatUI.Finch) do
      {:ok, %Finch.Response{status: s}} when s in 200..299 -> :ok
      other -> {:error, other}
    end
  end

  defp get(path) do
    req = Finch.build(:get, base_url() <> path, default_headers())
    Finch.request(req, AutomatUI.Finch)
  end

  defp base_url, do: "https://#{@service_host}:#{@service_port}"

  defp default_headers do
    token = File.read!(@token_path)
    [{"Authorization", "Bearer #{String.trim(token)}"}, {"Content-Type", "application/json"}]
  end
end
