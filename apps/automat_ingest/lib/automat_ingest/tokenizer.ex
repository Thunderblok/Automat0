defmodule AutomatIngest.Tokenizer do
  @moduledoc false
  require Logger
  alias Tokenizers, as: HF

  # Minimal wrapper to load a tokenizer and test encoding
  def load(path) do
    case HF.Tokenizer.from_file(path) do
      {:ok, t} -> {:ok, t}
      {:error, r} -> {:error, r}
    end
  end

  def encode!(t, text) when is_binary(text) do
    {:ok, ids} = HF.Tokenizer.encode(t, text)
    ids
  end
end
