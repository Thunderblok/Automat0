defmodule AutomatBus.Contracts do
  @moduledoc """
  JSON contracts for worker heartbeats and promotion events, validated via ExJsonSchema.
  """

  alias ExJsonSchema.Schema
  alias ExJsonSchema.Validator

  @schemas %{
    "heartbeat.hello" => %{
      "type" => "object",
      "required" => ["type", "trial_id", "timestamp"],
      "properties" => %{
        "type" => %{"const" => "hello"},
        "trial_id" => %{"type" => "string"},
        "timestamp" => %{"type" => "number"},
        "meta" => %{"type" => "object"}
      },
      "additionalProperties" => true
    },
    "heartbeat.epoch" => %{
      "type" => "object",
      "required" => ["type", "trial_id", "epoch", "metrics", "timestamp"],
      "properties" => %{
        "type" => %{"const" => "epoch"},
        "trial_id" => %{"type" => "string"},
        "epoch" => %{"type" => "integer", "minimum" => 0},
        "metrics" => %{"type" => "object"},
        "timestamp" => %{"type" => "number"}
      },
      "additionalProperties" => true
    },
    "heartbeat.checkpoint" => %{
      "type" => "object",
      "required" => ["type", "trial_id", "path", "timestamp"],
      "properties" => %{
        "type" => %{"const" => "checkpoint"},
        "trial_id" => %{"type" => "string"},
        "path" => %{"type" => "string"},
        "timestamp" => %{"type" => "number"}
      },
      "additionalProperties" => true
    },
    "heartbeat.final" => %{
      "type" => "object",
      "required" => ["type", "trial_id", "metrics", "timestamp"],
      "properties" => %{
        "type" => %{"const" => "final"},
        "trial_id" => %{"type" => "string"},
        "metrics" => %{"type" => "object"},
        "timestamp" => %{"type" => "number"}
      },
      "additionalProperties" => true
    },
    "promotion.event" => %{
      "type" => "object",
      "required" => ["type", "study_id", "trial_id", "epoch", "metric", "value", "timestamp"],
      "properties" => %{
        "type" => %{"const" => "promotion"},
        "study_id" => %{"type" => "string"},
        "trial_id" => %{"type" => "string"},
        "epoch" => %{"type" => "integer", "minimum" => 0},
        "metric" => %{"type" => "string"},
        "value" => %{"type" => "number"},
        "timestamp" => %{"type" => "number"}
      },
      "additionalProperties" => true
    }
  }

  @compiled Enum.into(@schemas, %{}, fn {k, v} -> {k, Schema.resolve(v)} end)

  @doc """
  Validate a payload map against a named schema. Returns :ok or {:error, errors}.
  """
  def validate(name, payload) when is_binary(name) and is_map(payload) do
    case Map.fetch(@compiled, name) do
      {:ok, schema} ->
        case Validator.validate(schema, payload) do
          :ok -> :ok
          {:error, errs} -> {:error, errs}
        end
      :error -> {:error, {:schema_not_found, name}}
    end
  end
end
