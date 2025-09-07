#!/usr/bin/env python3
import sys, json, time, os, signal
from datetime import datetime

HEARTBEAT_FLUSH_EVERY = 1


def log(frame):
    sys.stdout.write(json.dumps(frame) + "\n")
    sys.stdout.flush()


def main():
    # Expect a single JSON arg with trial config
    if len(sys.argv) < 2:
        log({"type": "error", "message": "missing cfg arg"}); return 2
    try:
        cfg = json.loads(sys.argv[1])
    except Exception as e:
        log({"type": "error", "message": f"bad cfg json: {e}"}); return 2

    trial_id = cfg.get("trial_id", f"trial-{int(time.time())}")
    artifacts_uri = cfg.get("artifacts_uri", f"/tmp/{trial_id}")
    os.makedirs(artifacts_uri, exist_ok=True)

    # Optional: MLflow setup if env configured
    mlflow_enabled = False
    mlflow = None  # type: ignore
    try:
        import mlflow
        tracking_uri = os.environ.get("MLFLOW_TRACKING_URI")
        if tracking_uri:
            mlflow.set_tracking_uri(tracking_uri)
            mlflow.set_experiment(cfg.get("experiment", "automat-default"))
            mlflow.start_run(run_name=trial_id)
            mlflow.log_params({
                k: v for k, v in cfg.items() if isinstance(v, (str, int, float, bool))
            })
            mlflow_enabled = True
    except Exception as e:
        # Stay quiet; fall back to JSONL heartbeats only
        mlflow_enabled = False

    # Hello heartbeat
    log({
        "type": "hello",
        "trial_id": trial_id,
        "hostname": os.uname().nodename,
        "pid": os.getpid(),
        "ts": datetime.utcnow().isoformat()+"Z",
        "tokenizer": cfg.get("tokenizer"),
        "actual_batch": cfg.get("batch", 8),
    })

    # Simulate a tiny 3-epoch run; later swap for true Cerebros training
    task_type = cfg.get("task_type", "classification")
    patience = int(cfg.get("patience", 3))
    best = None
    bad_epochs = 0
    last_primary = None

    def primary_metric(m):
        # Choose by task
        if task_type == "classification":
            return m.get("val_accuracy")
        elif task_type == "generation":
            return -m.get("val_perplexity") if m.get("val_perplexity") is not None else None
        else:
            return -m.get("val_loss") if m.get("val_loss") is not None else None

    for epoch in range(1, 4):
        # synthetic metrics
        metrics = {"val_accuracy": 0.3 + epoch * 0.05, "val_loss": 1.0 - epoch * 0.1, "tokens_per_sec": 5000 + 50 * epoch}
        if task_type == "generation":
            metrics = {"val_perplexity": 12.3 - epoch * 0.4, "tokens_per_sec": 5200 + 60 * epoch}
        pm = primary_metric(metrics)
        if pm is not None:
            if (last_primary is not None) and (pm <= last_primary):
                bad_epochs += 1
            else:
                bad_epochs = 0
            last_primary = pm
        # heartbeat
        log({"type": "epoch", "trial_id": trial_id, "epoch": epoch, "metrics": metrics})
        if mlflow_enabled:
            try:
                mlflow.log_metrics(metrics, step=epoch)
            except Exception:
                pass
        time.sleep(0.2)
        if bad_epochs >= patience:
            break

    # Final heartbeat
    final_best = {"name": "val_accuracy", "value": 0.42} if task_type == "classification" else {"name": "val_perplexity", "value": 12.3}
    ckpt = os.path.join(artifacts_uri, "ckpt.pt")
    with open(ckpt, "wb") as f:
        f.write(b"demo")
    log({"type": "final", "trial_id": trial_id, "best": final_best, "checkpoint": ckpt})
    if mlflow_enabled:
        try:
            mlflow.log_artifact(ckpt)
            mlflow.end_run()
        except Exception:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
