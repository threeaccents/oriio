defmodule MahiTest do
  use ExUnit.Case
  doctest Mahi

  test "greets the world" do
    assert Mahi.hello() == :world
  end
end
