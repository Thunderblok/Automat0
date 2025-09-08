defmodule AutomatCore.Promoter do
  @moduledoc """
  Simple promotion engine that tracks best metric per trial and emits promotion events.
  """
  require Logger

  @type state :: %{optional(String.t()) => %{best: number(), epoch: non_neg_integer(), metric: String.t()}}

  @doc """
  Update the promoter with a new metric value for a trial.

  Inputs:
  - state: promoter state map
  - study_id: string
  - trial_id: string
  - event: map with keys "epoch", "metrics" (map) and optional "primary_metric"

  Returns {new_state, promotion_event_or_nil}
  """
  @spec update(state(), String.t(), String.t(), map()) :: {state(), map() | nil}
  def update(state, study_id, trial_id, %{"epoch" => epoch} = ev) when is_integer(epoch) do
    metric_name = ev["primary_metric"] || pick_primary_metric(ev["metrics"] || %{})
    with true <- is_binary(metric_name),
         {:ok, val} <- fetch_metric(ev["metrics"], metric_name) do
      prev = Map.get(state, trial_id)
      better? = better?(prev, val)
      new_state = if better?, do: Map.put(state, trial_id, %{best: val, epoch: epoch, metric: metric_name}), else: state
      promotion = if better?, do: promotion_event(study_id, trial_id, epoch, metric_name, val), else: nil
      {new_state, promotion}
    else
      _ -> {state, nil}
    end
  end

  def update(state, _study_id, _trial_id, _), do: {state, nil}

  defp fetch_metric(%{} = metrics, name) do
    case Map.fetch(metrics, name) do
      {:ok, v} when is_number(v) -> {:ok, v}
      _ -> :error
    end
  end

  defp pick_primary_metric(%{} = metrics) do
    cond do
      Map.has_key?(metrics, "val_loss") -> "val_loss"
      Map.has_key?(metrics, "val_accuracy") -> "val_accuracy"
      Map.has_key?(metrics, "loss") -> "loss"
      true -> nil
    end
  end

  defp better?(nil, _v), do: true
  # For losses, smaller is better; for accuracy, larger is better. Infer by name.
  defp better?(%{best: prev, metric: name}, v) when is_number(prev) and is_number(v) do
    if String.contains?(name, "loss"), do: v < prev, else: v > prev
  end

  defp promotion_event(study_id, trial_id, epoch, metric, value) do
    %{
      "type" => "promotion",
      "study_id" => study_id,
      "trial_id" => trial_id,
      "epoch" => epoch,
      "metric" => metric,
      "value" => value,
      "timestamp" => System.system_time(:second)
    }
  end
end
