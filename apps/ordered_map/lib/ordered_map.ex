defmodule OrderedMap do
  @moduledoc """
  OrderedMap is a map with its keys being ordered.
  It is backed by the AVL Bst

  OrderedMap.new()
  |> OrderedMap.put(1, nil)
  |> OrderedMap.put(2, nil)

  OrderedMap.get(map, 1)

  IO.inspect(map)


  """

  defstruct ~w(root)a

  def new(), do: %__MODULE__{}

  def put(map, key, value) do
    %__MODULE__{map | root: insert_node(map.root, key, value)}
  end

  def get(map, key) do
    case search_node(map.root, key) do
      nil -> nil
      node -> node.value
    end
  end

  defp search_node(nil, _), do: nil

  defp search_node(%Node{key: node_key} = node, key) do
    case compare(node_key, key) do
      :eq -> node
      :lt -> search_node(node.left, key)
      :gt -> search_node(node.right, key)
    end
  end

  def insert_node(nil, key, value), do: %Node{key: key, value: value, height: 1}

  def insert_node(%Node{key: node_key} = node, key, value) do
    case compare(node_key, key) do
      :eq -> %Node{node | key: key, value: value}
      :lt -> Node.balance(%Node{node | left: insert_node(node.left, key, value)})
      :gt -> Node.balance(%Node{node | right: insert_node(node.right, key, value)})
    end
  end

  defp compare(a, b) do
    cond do
      a == b -> :eq
      a < b -> :gt
      a > b -> :lt
    end
  end
end
