# Automat0 Ops One-Pager

## Purpose

- How to run, test, build, and ship Automat0.

## Run (local stack)

- make up (starts Postgres, MinIO, MLflow, dev container)
- make logs | make ps | make down

## Test & Smokes

- Tokenizer: mix test apps/automat_ingest/test/tokenizer_serving_test.exs
- Trial worker: make trial-smoke
- Intake FSM: make intake-smoke

## Build

- Dev container: devcontainer/Dockerfile (or Dockerfile.cuda for GPU)
- MLflow image: docker/mlflow.Dockerfile

## Observability

- Metrics via MLflow; events via MQTT/PubSub.

## Security

- Default creds are dev-only (MinIO). Rotate for prod; add gitleaks/Trivy in CI.
