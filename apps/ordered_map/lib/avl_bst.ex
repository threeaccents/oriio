defmodule AvlBst do
  @moduledoc """
  Avl balanced BST tree
  """
  defstruct root: nil

  defmodule Node do
    defstruct ~w(value left right height)a

    def rotate_left(%__MODULE__{right: right_node} = node) do
      center_node = right_node.left

      updated_node = %__MODULE__{node | right: center_node} |> update_height()

      updated_right_node = %__MODULE__{right_node | left: updated_node} |> update_height()

      updated_right_node
    end

    def rotate_right(%__MODULE__{left: left_node} = node) do
      center_node = left_node.right

      updated_node = %__MODULE__{node | left: center_node} |> update_height()

      updated_left_node = %__MODULE__{left_node | right: updated_node} |> update_height()

      updated_left_node
    end

    def balance(%__MODULE__{} = node) do
      height(node.left) - height(node.right)
    end

    def balance(nil), do: 0

    def height(%__MODULE__{height: height}), do: height
    def height(nil), do: 0

    def apply_rotation(%Node{left: left_node, right: right_node} = node) do
      balance = balance(node)
      left_node_balance = balance(left_node)
      right_node_balance = balance(right_node)

      cond do
        balance > 1 and left_node_balance < 0 ->
          node = %__MODULE__{node | left: rotate_left(left_node)}
          rotate_right(node)

        balance > 1 ->
          rotate_right(node)

        balance < -1 and right_node_balance > 0 ->
          node = %__MODULE__{node | right: rotate_right(right_node)}
          rotate_left(node)

        balance < -1 ->
          rotate_left(node)

        true ->
          node
      end
    end

    def update_height(%__MODULE__{left: left_node, right: right_node} = node) do
      node_heights = [height(left_node), height(right_node)]

      max_hight = Enum.max(node_heights)

      %__MODULE__{node | height: max_hight + 1}
    end
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

  defp insert_node(nil, element), do: %Node{value: element, height: 1}

  defp insert_node(node = %Node{value: node_value}, element) do
    updated_node =
      case compare(node_value, element) do
        :eq -> %Node{node | value: element}
        :lt -> %Node{node | left: insert_node(node.left, element)}
        :gt -> %Node{node | right: insert_node(node.right, element)}
      end

    updated_node
    |> Node.update_height()
    |> Node.apply_rotation()
  end

  defp compare(a, b) do
    cond do
      a == b -> :eq
      a < b -> :gt
      a > b -> :lt
    end
  end
end
