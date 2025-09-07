# Automat

A dockerized BEAM umbrella orchestrator for Python-based Cerebros trials.

- Elixir umbrella: Nx/NimbleParsec/Tokenizers-powered ingest and workers
- Python worker runner with optional MLflow logging
- Devcontainer for CPU and CUDA workflows
- Docker Compose stack: Postgres (MLflow backend), MinIO (artifact store), MLflow server

See `Makefile` for common tasks.
