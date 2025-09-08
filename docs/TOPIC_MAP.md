# Automat Topics (v0)

Events (to be published by AutomatWorkers and mirrored by AutomatMetrics):
- heartbeat.hello {trial_id, actual_batch, tokens_sec?}
- heartbeat.epoch {trial_id, epoch, primary_metric, tokens_sec, actual_batch}
- heartbeat.checkpoint {trial_id, epoch, path}
- heartbeat.final {trial_id, primary_metric, path}

Notes:
- Orchestrator and Dashboard subscribe to the above.
- Device profiles (CPU-POC, T4-16GB) determine initial batch; worker can downshift on OOM and report actual_batch.
