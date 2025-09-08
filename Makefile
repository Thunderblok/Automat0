bootstrap:
	mix deps.get || true
	[ -d /opt/py ] || python3 -m venv /opt/py
	/opt/py/bin/pip install -U pip
	if [ -f python/requirements.txt ]; then /opt/py/bin/pip install -r python/requirements.txt; fi
	mix assets.setup || true

# Tokenization pipeline smoke test
# Requires Tokenizers + Nx in BEAM deps and a small tokenizer.json in docs/
# Creates docs/demo_shard.jsonl.gz and META/MANIFEST sidecars

.PHONY: tokenize-smoke

tokenize-smoke:
	iex -S mix run -e "AutomatIngest.Smoke.run()"

# Trial worker smoke: spawns python/cerebros_run.py via Venomous, streams heartbeats
.PHONY: trial-smoke

trial-smoke:
	iex -S mix run -e "AutomatWorkers.Smoke.run_trial()"

# Trial intake smoke via FSM
.PHONY: intake-smoke
intake-smoke:
	iex -S mix run -e 'AutomatCore.TrialSupervisor.start_trial(%{trial: %{"trial_id" => "intake-smoke", "task_type" => "classification", "artifacts_uri" => "/tmp/intake-smoke"}})'

# MLflow + Postgres + MinIO stack
.PHONY: up down logs ps
up:
	docker compose --env-file .env.example -f docker-compose.yml up -d --build

down:
	docker compose -f docker-compose.yml down -v

logs:
	docker compose -f docker-compose.yml logs -f --tail=100

ps:
	docker compose -f docker-compose.yml ps
