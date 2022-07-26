defmodule TransformerTest do
  use ExUnit.Case
  doctest Transformer

  test "greets the world" do
    assert Transformer.hello() == :world
  end
end
