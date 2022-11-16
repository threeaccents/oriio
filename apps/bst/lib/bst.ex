defmodule Bst do
  @moduledoc """
  Bst data structure
  """

  defstruct ~w(root)a

  defmodule Node do
    defstruct ~w(value left right)a
  end

  def new(elements \\ []) do
    tree = %__MODULE__{}

    for elem <- elements, reduce: tree do
      acc ->
        insert(acc, elem)
    end
  end

  def insert(tree, element) do
    %__MODULE__{tree | root: insert_node(tree.root, element)}
  end

  defp insert_node(nil, element), do: %Node{value: element}

  defp insert_node(node = %Node{value: node_value}, element) do
    case compare(node_value, element) do
      :eq -> %Node{node | value: element}
      :lt -> %Node{node | left: insert_node(node.left, element)}
      :gt -> %Node{node | right: insert_node(node.right, element)}
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
