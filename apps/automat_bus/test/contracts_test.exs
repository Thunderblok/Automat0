defmodule AutomatBus.ContractsTest do
  use ExUnit.Case, async: true

  test "heartbeat.epoch schema accepts valid payload" do
    payload = %{"type" => "epoch", "trial_id" => "t1", "epoch" => 1, "metrics" => %{"val_loss" => 0.5}, "timestamp" => 1_733_000_000}
    assert :ok = AutomatBus.Contracts.validate("heartbeat.epoch", payload)
  end

  test "promotion.event schema rejects missing fields" do
    payload = %{"type" => "promotion", "study_id" => "s1"}
    assert {:error, _} = AutomatBus.Contracts.validate("promotion.event", payload)
  end
end
