defmodule AutomatIngest.Smoke do
  require Logger

  @tokenizer "docs/tokenizer.json"

  def run() do
    {:ok, tok} = AutomatIngest.Tokenizer.load(@tokenizer)
    ids = AutomatIngest.Tokenizer.encode!(tok, "hello world")
    Logger.info("Encoded: #{inspect(ids)}")
    :ok
  end
end
