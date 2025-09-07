defmodule AutomatCore.TrialSpecParser do
  @moduledoc """
  Tiny DSL parser for starting trials from a one-liner, e.g.:

    "task:cls epochs:3 batch:32 device:t4 tokenizer:bert-base-uncased"

  Returns {:ok, map} or {:error, reason}.
  """
  import NimbleParsec

  ws      = ascii_string([?\s, ?\t], min: 1)
  digits  = ascii_string([?0..?9], min: 1)
  ident   = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?/, ?:, ?.], min: 1)
  key     = choice([
               string("task"), string("epochs"), string("batch"), string("device"), string("tokenizer"),
               string("patience"), string("artifacts"), string("trial_id")
             ])

  pair =
    key
    |> unwrap_and_tag(:key)
    |> ignore(string(":"))
    |> choice([
      digits |> map({String, :to_integer, []}) |> unwrap_and_tag(:int),
      ident  |> unwrap_and_tag(:ident)
    ])
    |> reduce({__MODULE__, :to_kv, []})

  line =
    ignore(optional(ws))
    |> concat(pair)
    |> repeat(ignore(ws) |> concat(pair))
    |> ignore(optional(ws))
    |> eos()
    |> reduce({Enum, :into, [%{}]})

  defparsec(:parse!, line)

  def parse(str) when is_binary(str) do
    case parse!(str) do
      # NimbleParsec returns a list of results; our line reducer emits a single map
      {:ok, [map], _, _, _, _} when is_map(map) -> {:ok, coerce(map)}
      {:ok, map, _, _, _, _} when is_map(map) -> {:ok, coerce(map)}
      {:error, reason, rest, _ctx, _line, _col} -> {:error, {reason, rest}}
    end
  end

  # Convert strings to atoms/ints where appropriate
  defp coerce(map) do
    map
    |> maybe_atom(:task)
    |> maybe_atom(:device)
    |> maybe_int(:epochs)
    |> maybe_int(:batch)
    |> maybe_int(:patience)
  end

  defp maybe_atom(m, k) do
    case Map.fetch(m, k) do
      {:ok, v} when is_binary(v) -> Map.put(m, k, String.to_atom(v))
      {:ok, _v} -> m
      :error -> m
    end
  end
  defp maybe_int(m, _k), do: m

  # Transform parsed key/value tuples into a list for Enum.into/2
  def to_kv([{:key, k}, {:int, n}]), do: {String.to_atom(k), n}
  def to_kv([{:key, k}, {:ident, v}]), do: {String.to_atom(k), v}
end
