defmodule AutomatWorkers.PyTrial do
  @moduledoc """
  Minimal Venomous-based Python trial launcher.
  Spawns python/cerebros_run.py with a JSON config; streams JSONL heartbeats.
  """
  use GenServer
  require Logger

  @port_opts [:binary, :exit_status]

  def start_link(cfg), do: GenServer.start_link(__MODULE__, cfg)

  @impl true
  def init(cfg) do
    env = [{~c"CUDA_VISIBLE_DEVICES", String.to_charlist(cfg[:gpu] || System.get_env("CUDA_VISIBLE_DEVICES", ""))}]

    py =
      System.get_env("PYTHON_BIN") ||
        System.find_executable("python3") ||
        System.find_executable("python") ||
        "/usr/bin/python3"

    # Resolve script path; prefer umbrella root python/ dir, fallback to priv/
    umbrella_root = Path.expand("../../../../", __DIR__)
    cwd = File.cwd!()
    up1 = Path.expand("..", cwd)
    up2 = Path.expand("../..", cwd)
    up3 = Path.expand("../../..", cwd)
    script_candidates = [
      Path.join([umbrella_root, "python", "cerebros_run.py"]),
      Path.join([up3, "python", "cerebros_run.py"]),
      Path.join([up2, "python", "cerebros_run.py"]),
      Path.join([up1, "python", "cerebros_run.py"]),
      Path.join([cwd, "python", "cerebros_run.py"]),
      Path.join([Application.app_dir(:automat_workers), "priv", "cerebros_run.py"])
    ]
    script = Enum.find(script_candidates, &File.exists?/1)
    script || raise "cerebros_run.py not found in candidates: #{inspect(script_candidates)}"
    args = [script, Jason.encode!(cfg[:trial] || %{})]
    workdir = Path.dirname(script)
    Logger.info("Starting python worker: #{py} #{inspect(args)}")
    port =
      Port.open({:spawn_executable, String.to_charlist(py)},
        @port_opts ++ [args: Enum.map(args, &String.to_charlist/1), env: env, cd: String.to_charlist(workdir)]
      )
    {:ok, %{port: port, trial_id: get_in(cfg, [:trial, "trial_id"]) || "unknown", buf: ""}}
  end

  @impl true
  def handle_info({port, {:data, chunk}}, %{port: port} = st) do
    data = st.buf <> chunk
    {lines, rest} =
      case String.split(data, "\n") do
        [] -> {[], ""}
        parts -> {Enum.slice(parts, 0..-2//1), List.last(parts) || ""}
      end

    Enum.each(lines, fn line ->
      line = String.trim(line)
      if line != "" do
        case Jason.decode(line) do
          {:ok, event} ->
            # Validate against contracts (best-effort)
            _ = case event["type"] do
              "hello" -> AutomatBus.Contracts.validate("heartbeat.hello", event)
              "epoch" -> AutomatBus.Contracts.validate("heartbeat.epoch", event)
              "checkpoint" -> AutomatBus.Contracts.validate("heartbeat.checkpoint", event)
              "final" -> AutomatBus.Contracts.validate("heartbeat.final", event)
              _ -> :ok
            end
            # Mirror to in-memory metrics store
            AutomatMetrics.ingest(st.trial_id, event)
            # Publish to bus topics
            AutomatBus.publish(AutomatBus.topic(:heartbeats, st.trial_id), {:heartbeat, event})
            AutomatBus.publish(AutomatBus.topic(:events, st.trial_id), {:event, event})
            # Telemetry
            tokens = case event do
              %{"metrics" => %{"tokens_per_sec" => tps}} when is_number(tps) -> tps
              _ -> 0
            end
            :telemetry.execute([:automat, :trial, :heartbeat], %{count: 1, tokens_per_sec: tokens}, %{trial_id: st.trial_id, type: event["type"]})
            send(self(), {:event, event})
          _ ->
            Logger.warning("non-json from worker: #{inspect(line)}")
        end
      end
    end)

    {:noreply, %{st | buf: rest}}
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = st) do
    Logger.info("python worker exited: #{status}")
    {:stop, :normal, st}
  end

  @impl true
  def handle_info({:event, ev}, st) do
    case ev do
      %{"type" => "final"} -> {:stop, :normal, st}
      _ -> {:noreply, st}
    end
  end

  # Utility for smoke test
  def run_once() do
    cfg = %{trial: %{"trial_id" => "trial-smoke", "task_type" => "classification", "artifacts_uri" => "/tmp/trial-smoke"}}
    {:ok, pid} = start_link(cfg)
    # Wait for a few events then stop
    receive do
      {:event, %{"type" => "final"}} -> :ok
    after
      5_000 -> :timeout
    end
    :ok
  end
end
