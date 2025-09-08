defmodule AutomatIngest.Tokenizer do
  @moduledoc """
  Nx.Serving wrapper over rust-tokenizers; batches and returns id/mask.
  """
  require Logger

  def serving(tokenizer_json_path, opts \\ []) do
    with {:ok, tok} <- Tokenizers.Tokenizer.from_file(tokenizer_json_path) do
      batch_size = opts[:batch_size] || 2048

      # Turn a list of %{text, max_len} into a Nx.Batch of tuple tensors: {ids, mask}
      preprocess = fn input ->
        entries =
          case input do
            list when is_list(list) -> list
            %Nx.Batch{} = batch ->
              raise ArgumentError, "expected list of %{text, max_len}, got Nx.Batch in client input"
            other -> raise ArgumentError, "unsupported input for tokenizer: #{inspect(other)}"
          end

        # Choose max length per batch to be robust if caller passes varying lengths
        max_len =
          entries
          |> Enum.map(&(&1.max_len))
          |> Enum.max(fn -> raise ArgumentError, "empty input list for tokenizer" end)

        encoded =
          Enum.map(entries, fn %{text: t} ->
            {:ok, enc} = Tokenizers.Tokenizer.encode(tok, t, add_special_tokens: true)

            transforms = [
              Tokenizers.Encoding.Transformation.truncate(max_len, direction: :right),
              Tokenizers.Encoding.Transformation.pad(max_len,
                direction: :right,
                pad_id: 0,
                pad_type_id: 0,
                pad_token: "[PAD]"
              )
            ]

            enc = Tokenizers.Encoding.transform(enc, transforms)

            ids = Tokenizers.Encoding.get_ids(enc)
            mask = Tokenizers.Encoding.get_attention_mask(enc)

            # Use tuple containers for guaranteed Nx container compatibility
            {Nx.tensor(ids, type: :s64), Nx.tensor(mask, type: :s64)}
          end)

        {Nx.Batch.stack(encoded), :ok}
      end

      # Convert tensors {ids, mask} back to list of maps for JSONL lines
      postprocess = fn {%{}} = unexpected, _info ->
        # Guard against unexpected shapes from the serving function
        raise "unexpected output from tokenizer serving: #{inspect(unexpected)}"
      end

      postprocess = fn {{ids, mask}, _metadata}, _info ->
        batch = Nx.axis_size(ids, 0)
        seq_len = Nx.axis_size(ids, 1)
        ids_list = Nx.to_flat_list(ids)
        mask_list = Nx.to_flat_list(mask)
        ids_rows = Enum.chunk_every(ids_list, seq_len)
        mask_rows = Enum.chunk_every(mask_list, seq_len)
        Enum.zip(ids_rows, mask_rows)
        |> Enum.map(fn {ids_row, mask_row} -> %{input_ids: ids_row, attention_mask: mask_row} end)
      end

      Nx.Serving.jit(&Function.identity/1)
      |> Nx.Serving.client_preprocessing(preprocess)
      |> Nx.Serving.client_postprocessing(postprocess)
      |> Nx.Serving.batch_size(batch_size)
      |> Nx.Serving.process_options(
        batch_size: batch_size,
        batch_timeout: 10,
        partitions: true
      )
    else
      {:error, reason} -> raise "Tokenizer load failed: #{inspect(reason)}"
    end
  end
end
