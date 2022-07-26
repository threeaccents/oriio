defmodule DebugTest do
  use ExUnit.Case
  doctest Debug

  test "greets the world" do
    assert Debug.hello() == :world
  end
end
