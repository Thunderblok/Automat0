# Automat0 — fast executor for Cerebros

Automat0 is a BEAM umbrella microservice that feeds Cerebros with tokenized, batched data and mirrors telemetry to the bus. It’s the low-level executor under a slow/steady planner (Thunderline): keep policy slow and stable; keep execution hot and parallel.

Highlights:
- Ingest/tokenize pipeline (Tokenizers + Nx) — smoke passing
- Trial intake and per-trial FSM that launches Python workers
- Bus via Phoenix.PubSub (ZeroMQ/MQTT bridges next)
- Metrics/artifacts via MLflow (Postgres backend + MinIO artifacts)
- Devcontainer and Docker Compose for reproducible local runs

## Quickstart

1) Bring up backing services (Postgres + MinIO + MLflow + dev container):
	make up

2) Tokenizer smoke:
	mix test apps/automat_ingest/test/tokenizer_serving_test.exs

3) Trial smoke (direct worker):
	make trial-smoke

4) Trial intake smoke (FSM):
	make intake-smoke

Open MLflow at http://localhost:5000. MinIO Console at http://localhost:9001 (minio/minio123).

## Interfaces (tight contracts)

TrialSpec → Automat0:
{trial_id, task_type, tokenizer_ref, device_profile, seq_len, embed_dim, budget_seconds, dataset_uri, primary_metric}

Control → Worker (to be ZeroMQ REQ):
- train with {trial_id, dataset_uri, hparams}
- cancel_after_epoch

Heartbeats ← Worker:
- hello: {trial_id, actual_batch, tokenizer_ref}
- epoch: {trial_id, epoch, metrics{primary,tokens_per_s,...}}
- checkpoint: {trial_id, path}
- final: {trial_id, status, best_metric{name,value}}

Mirrors → Bus:
- automat.heartbeats.<trial_id>
- automat.events.<trial_id>

## Observability
- Queue depth, batch size effective vs target, OOM backoffs
- tokens/sec, time/epoch, shard rate
- Trial timers, patience state, last heartbeat offset

## Roadmap (48h Sprint Orders)
- Add ZeroMQ REQ/REP for control and PUB for heartbeats; mirror to MQTT/NATS
- Backpressure and device profiles; batch auto-dial on OOM
- Early stop with patience and min_delta
- Artifacts to S3 (MinIO); metrics to MLflow; publish promotion-candidate event
- Two smokes: classification (val_accuracy) and generation (val_perplexity with clean cancel)

See docs/ for deeper architecture notes.
