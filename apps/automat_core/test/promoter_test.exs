defmodule AutomatCore.PromoterTest do
  use ExUnit.Case, async: true
  alias AutomatCore.Promoter

  test "promotes on first metric and improves for loss" do
    s0 = %{}
    {s1, ev1} = Promoter.update(s0, "study", "trial", %{"epoch" => 0, "metrics" => %{"val_loss" => 0.9}})
    assert ev1["type"] == "promotion"
    assert s1["trial"].best == 0.9
    {s2, ev2} = Promoter.update(s1, "study", "trial", %{"epoch" => 1, "metrics" => %{"val_loss" => 0.8}})
    assert ev2["value"] == 0.8
    assert s2["trial"].best == 0.8
    {s3, ev3} = Promoter.update(s2, "study", "trial", %{"epoch" => 2, "metrics" => %{"val_loss" => 0.85}})
    assert ev3 == nil
    assert s3["trial"].best == 0.8
  end

  test "promotes on higher accuracy" do
    s0 = %{}
    {s1, ev1} = Promoter.update(s0, "s", "t", %{"epoch" => 0, "metrics" => %{"val_accuracy" => 0.7}})
    assert ev1["metric"] == "val_accuracy"
    {s2, ev2} = Promoter.update(s1, "s", "t", %{"epoch" => 1, "metrics" => %{"val_accuracy" => 0.65}})
    assert ev2 == nil
    {_, ev3} = Promoter.update(s2, "s", "t", %{"epoch" => 2, "metrics" => %{"val_accuracy" => 0.75}})
    assert ev3["value"] == 0.75
  end
end
