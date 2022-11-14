defmodule BanzaiTest do
  use ExUnit.Case
  doctest Banzai

  test "greets the world" do
    assert Banzai.hello() == :world
  end
end
