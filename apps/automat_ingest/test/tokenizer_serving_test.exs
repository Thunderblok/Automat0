defmodule AutomatIngest.TokenizerServingTest do
  use ExUnit.Case, async: true

  test "encodes hello" do
    {:ok, tok} = AutomatIngest.Tokenizer.load("docs/tokenizer.json")
    ids = AutomatIngest.Tokenizer.encode!(tok, "hello")
    assert is_list(ids)
  end
end
