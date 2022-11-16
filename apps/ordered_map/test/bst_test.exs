defmodule BstTest do
  use ExUnit.Case

  test "test insert with no custom comparator" do
    tree =
      Bst.new()
      |> Bst.insert(5)
      |> Bst.insert(4)
      |> Bst.insert(2)
      |> Bst.insert(3)
      |> Bst.insert(9)

    assert %Bst{
             root: %Bst.Node{
               left: %Bst.Node{
                 left: %Bst.Node{
                   left: nil,
                   right: %Bst.Node{left: nil, right: nil, value: 3},
                   value: 2
                 },
                 right: nil,
                 value: 4
               },
               right: %Bst.Node{left: nil, right: nil, value: 9},
               value: 5
             }
           } = tree
  end

  test "avl insert" do
    tree =
      AvlBst.new()
      |> AvlBst.insert(5)
      |> AvlBst.insert(4)
      |> AvlBst.insert(3)
      |> AvlBst.insert(2)
      |> AvlBst.insert(1)
  end

  test "ordered map" do
    map =
      OrderedMap.new()
      |> OrderedMap.put(1, "hello")
      |> OrderedMap.put(2, "world")
      |> OrderedMap.put(3, "ipsum")
      |> OrderedMap.put(4, "lorem")

    IO.inspect(map)

    assert "hello" == OrderedMap.get(map, 1)
    assert "world" == OrderedMap.get(map, 2)
  end
end
