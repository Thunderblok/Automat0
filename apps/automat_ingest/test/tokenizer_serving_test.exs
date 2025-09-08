defmodule AutomatIngest.TokenizerServingTest do
  use ExUnit.Case, async: true

  @tok Path.expand("../../../docs/tokenizer.json", __DIR__)

  test "happy path: list -> tensors -> maps" do
    if not File.exists?(@tok) do
      IO.puts("skipping: missing tokenizer.json at #{@tok}")
      assert true
    else
      serving = AutomatIngest.Tokenizer.serving(@tok, batch_size: 8)
  inputs = [%{text: "hello world", max_len: 8}, %{text: "quick brown fox", max_len: 8}]
      out = Nx.Serving.run(serving, inputs)
      assert is_list(out) and length(out) == 2
      assert Enum.all?(out, fn m -> Map.has_key?(m, :input_ids) and Map.has_key?(m, :attention_mask) end)
      # lengths should equal max_len
      assert Enum.all?(out, fn m -> length(m.input_ids) == 8 and length(m.attention_mask) == 8 end)
    end
  end

  test "edge: mixed max_len -> batch max wins" do
    if not File.exists?(@tok) do
      IO.puts("skipping: missing tokenizer.json at #{@tok}")
      assert true
    else
      serving = AutomatIngest.Tokenizer.serving(@tok, batch_size: 8)
  inputs = [%{text: "hello", max_len: 4}, %{text: "quick", max_len: 6}]
      out = Nx.Serving.run(serving, inputs)
      assert Enum.all?(out, fn m -> length(m.input_ids) == 6 end)
    end
  end

  test "edge: empty list -> error" do
    if not File.exists?(@tok) do
      IO.puts("skipping: missing tokenizer.json at #{@tok}")
      assert true
    else
      serving = AutomatIngest.Tokenizer.serving(@tok, batch_size: 8)
      assert_raise ArgumentError, fn -> Nx.Serving.run(serving, []) end
    end
  end
end
