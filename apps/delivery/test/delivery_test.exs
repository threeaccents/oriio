defmodule DeliveryTest do
  use ExUnit.Case
  doctest Delivery

  test "greets the world" do
    assert Delivery.hello() == :world
  end
end
