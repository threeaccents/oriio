defmodule OrderedMap.Node do
  @compile {:inline,
            height: 1,
            rotate_left: 1,
            big_rotate_left: 1,
            big_rotate_right: 1,
            rotate_right: 1,
            balance: 1}

  defstruct ~w(key value left right height)a

  def rotate_left(%__MODULE__{right: right_node} = node) do
    center_node = right_node.left

    updated_node = %__MODULE__{node | right: center_node} |> fix_height()

    updated_right_node = %__MODULE__{right_node | left: updated_node} |> fix_height()

    updated_right_node
  end

  def rotate_right(%__MODULE__{left: left_node} = node) do
    center_node = left_node.right

    updated_node = %__MODULE__{node | left: center_node} |> fix_height()

    updated_left_node = %__MODULE__{left_node | right: updated_node} |> fix_height()

    updated_left_node
  end

  def big_rotate_left(%__MODULE__{right: right_node} = node) do
    rotate_left(%__MODULE__{node | right: rotate_right(right_node)})
  end

  def big_rotate_right(%__MODULE__{left: left_node} = node) do
    rotate_right(%__MODULE__{node | left: rotate_left(left_node)})
  end

  def height_balance(%__MODULE__{} = node) do
    height(node.left) - height(node.right)
  end

  def height_balance(nil), do: 0

  def height(%__MODULE__{height: height}), do: height
  def height(nil), do: 0

  def balance(%__MODULE__{left: left_node, right: right_node} = node) do
    node = fix_height(node)

    balance = height_balance(node)
    left_node_balance = height_balance(left_node)
    right_node_balance = height_balance(right_node)

    cond do
      balance > 1 and left_node_balance < 0 ->
        big_rotate_right(node)

      balance > 1 ->
        rotate_right(node)

      balance < -1 and right_node_balance > 0 ->
        big_rotate_left(node)

      balance < -1 ->
        rotate_left(node)

      true ->
        node
    end
  end

  def fix_height(%__MODULE__{left: left_node, right: right_node} = node) do
    node_heights = [height(left_node), height(right_node)]

    max_hight = Enum.max(node_heights)

    %__MODULE__{node | height: max_hight + 1}
  end
end