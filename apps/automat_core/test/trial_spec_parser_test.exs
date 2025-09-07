defmodule AutomatCore.TrialSpecParserTest do
  use ExUnit.Case, async: true

  alias AutomatCore.TrialSpecParser, as: P

  test "parses basic line" do
    {:ok, m} = P.parse("task:cls epochs:3 batch:32 device:t4")
    assert m[:task] == :cls
    assert m[:epochs] == 3
    assert m[:batch] == 32
    assert m[:device] == :t4
  end

  test "accepts tokenizer and artifacts" do
    {:ok, m} = P.parse("task:cls tokenizer:bert-base-uncased artifacts:/tmp/x trial_id:abc")
    assert m[:task] == :cls
    assert m[:tokenizer] == "bert-base-uncased"
    assert m[:artifacts] == "/tmp/x"
    assert m[:trial_id] == "abc"
  end

  test "errors on bad input" do
    assert {:error, _} = P.parse(":bad")
  end
end
