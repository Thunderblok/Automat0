# Automat Ingest/Tokenizer Contract (v0)

## Intake
- Shape: list of maps
  - {text: string, max_len: pos_integer}
- Batching: client_preprocessing stacks entries into Nx.Batch.
  - Per-batch max_len = max of provided max_len values.
- Tokenizer reference: docs/tokenizer.json (commit pinned by repo SHA)

## Output
- Shape: list of maps
  - {input_ids: [int], attention_mask: [int]}
- Shard: gzip JSONL at docs/demo_shard.jsonl.gz
- Target shard size: small demo; production to be configured.
- Manifest/meta: docs/DATASET_MANIFEST_TEMPLATE.yml, docs/DATASET_META_TEMPLATE.yml

## Error modes
- Empty input -> ArgumentError
- Bad tokenizer path -> raise with load failure
- Mixed lengths -> normalized to batch max_len

---

This spec is the minimal “don’t make me think” reference for downstream consumers.
