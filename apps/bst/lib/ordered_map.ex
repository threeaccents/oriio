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

  defmodule Node do
    @compile {:inline,
              height: 1, rotate_left: 1, rotate_right: 1, big_rotate_left: 1, big_rotate_right: 1}

    def rotate_left({k, v, l, {rk, rv, rl, rr, rh}, h}) do
      fix_height({rk, rv, fix_height({k, v, l, rl, h}), rr, rh})
    end

    def rotate_right({k, v, {lk, lv, ll, lr, lh}, r, h}) do
      fix_height({lk, lv, ll, fix_height({k, v, lr, r, h}), lh})
    end

    def big_rotate_left({k, v, l, r, h}) do
      rotate_left({k, v, l, rotate_right(r), h})
    end

    def big_rotate_right({k, v, l, r, h}) do
      rotate_right({k, v, rotate_left(l), r, h})
    end

    def height(_, _, _, _, height), do: height
    def height(nil), do: 0

    def fix_height({node_key, node_value, left_child, right_child, _height}) do
      height = max(height(left_child), height(right_child))

      {node_key, node_value, left_child, right_child, height}
    end
  end

  def new(), do: %__MODULE__{}

  # def new(elements) when is_list(elements) do
  #  map = %__MODULE__{}
  #
  # end

  def put(map, key, value) do
    %__MODULE__{map | root: insert_node(map.root, key, value)}
  end

  # def get(map, key) do
  #   case search_node(map.root, key) do
  #     nil -> nil
  #     node -> node.value
  #   end
  # end

  # defp search_node(nil, _), do: nil
  #
  # defp search_node(%Node{key: node_key} = node, key) do
  #   case compare(node_key, key) do
  #     :eq -> node
  #     :lt -> search_node(node.left, key)
  #     :gt -> search_node(node.right, key)
  #   end
  # end

  def insert_node(nil, key, value), do: {key, value, nil, nil, 1}

  def insert_node({node_key, node_value, left_node, right_node, height}, key, value) do
    case compare(node_key, key) do
      :eq ->
        {key, value, left_node, right_node, height}

      :lt ->
        balance({node_key, node_value, insert_node(left_node, key, value)})

      :gt ->
        balance({node_key, node_value, left_node, insert_node(right_node, key, value)})
    end
  end

  defp balance({_node_key, _node_value, left_child, right_child, _height} = node) do
    node = Node.fix_height(node)

    cond do
      Node.height(right_child) - Node.height(left_child) == 2 ->
        {_, _, right_node_left_child, right_node_right_child, _} = right_child

        if Node.height(right_node_left_child) <= Node.height(right_node_right_child) do
          Node.rotate_left(node)
        else
          Node.big_rotate_left(node)
        end

      Node.height(left_child) - Node.height(right_child) == 2 ->
        {_, _, left_node_left_child, left_node_right_child, _} = left_child

        if Node.height(left_node_right_child) <= Node.height(left_node_left_child) do
          Node.rotate_right(node)
        else
          Node.big_rotate_right(node)
        end

      true ->
        node
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
