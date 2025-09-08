defmodule AutomatIngest.Smoke do
  @moduledoc false
  require Logger

  @demo_tok "docs/tokenizer.json"

  def run do
    # Ensure required apps are running in umbrella (UI not needed here)
    Application.ensure_all_started(:automat_metrics)
    path = Path.expand(@demo_tok, File.cwd!())
    unless File.exists?(path), do: raise "missing tokenizer: #{path}"

    serving = AutomatIngest.Tokenizer.serving(path, batch_size: 8)
    req = [%{text: "hello world", max_len: 16}, %{text: "quick brown fox", max_len: 16}]
    out = Nx.Serving.run(serving, req)

    ds_root = Path.expand("docs/demo_dataset", File.cwd!())
    AutomatIngest.ShardWriter.write!(ds_root, path, out, split: "train", shard_name: "shard-000001.jsonl.gz")
    :ok
  end
end
