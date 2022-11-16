defmodule OrderedMapTest do
  use ExUnit.Case

  describe "put/3" do
    test "it sets value as root when map is empty" do
      map =
        OrderedMap.new()
        |> OrderedMap.put(1, "bar")

      assert %OrderedMap{
               root: %OrderedMap.Node{
                 key: 1,
                 height: 1,
                 left: nil,
                 right: nil,
                 value: "bar"
               }
             } = map
    end

    test "it puts lesser values on the left side of the node" do
      map =
        OrderedMap.new()
        |> OrderedMap.put(10, "bar")
        |> OrderedMap.put(9, "foo")

      assert %OrderedMap{
               root: %OrderedMap.Node{
                 key: 10,
                 height: 2,
                 left: %OrderedMap.Node{
                   key: 9,
                   value: "foo",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 right: nil,
                 value: "bar"
               }
             } = map
    end

    test "it big left rotates an unbalanced tree" do
      """
      unbalanced tree looks like:

          10
           \
           15
           /
          13

      after big lef rotation

        13
       / \
      10  15
      """

      map =
        OrderedMap.new()
        |> OrderedMap.put(10, "bar")
        |> OrderedMap.put(15, "faz")
        |> OrderedMap.put(13, "foo")

      assert %OrderedMap{
               root: %OrderedMap.Node{
                 key: 13,
                 height: 2,
                 left: %OrderedMap.Node{
                   key: 10,
                   value: "bar",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 right: %OrderedMap.Node{
                   key: 15,
                   value: "faz",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 value: "foo"
               }
             } = map
    end

    test "it big right rotates an unbalanced tree" do
      """
      unbalanced tree looks like:

          10
          /
         6
          \
           9

      after big lef rotation

        9
       / \
      6  10
      """

      map =
        OrderedMap.new()
        |> OrderedMap.put(10, "bar")
        |> OrderedMap.put(6, "faz")
        |> OrderedMap.put(9, "foo")

      assert %OrderedMap{
               root: %OrderedMap.Node{
                 key: 9,
                 height: 2,
                 left: %OrderedMap.Node{
                   key: 6,
                   value: "faz",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 right: %OrderedMap.Node{
                   key: 10,
                   value: "bar",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 value: "foo"
               }
             } = map
    end

    test "it left rotates an unbalanced tree" do
      """
      unbalanced tree looks like:

        8
         \
          9
           \
            10

      After rotating left:

        9
       / \
      8   10

      """

      map =
        OrderedMap.new()
        |> OrderedMap.put(8, "bar")
        |> OrderedMap.put(9, "foo")
        |> OrderedMap.put(10, "faz")

      assert %OrderedMap{
               root: %OrderedMap.Node{
                 key: 9,
                 height: 2,
                 left: %OrderedMap.Node{
                   key: 8,
                   value: "bar",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 right: %OrderedMap.Node{
                   key: 10,
                   value: "faz",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 value: "foo"
               }
             } = map
    end

    test "it right rotates an unbalanced tree" do
      """
      unbalanced tree looks like:

        10
        /
       9
      /
      8

      After rotating left:

        9
       / \
      8   10

      """

      map =
        OrderedMap.new()
        |> OrderedMap.put(10, "bar")
        |> OrderedMap.put(9, "foo")
        |> OrderedMap.put(8, "faz")

      assert %OrderedMap{
               root: %OrderedMap.Node{
                 key: 9,
                 height: 2,
                 left: %OrderedMap.Node{
                   key: 8,
                   value: "faz",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 right: %OrderedMap.Node{
                   key: 10,
                   value: "bar",
                   left: nil,
                   right: nil,
                   height: 1
                 },
                 value: "foo"
               }
             } = map
    end
  end

  describe "get/2" do
    test "it gets value from key" do
      map =
        OrderedMap.new()
        |> OrderedMap.put(10, "bar")
        |> OrderedMap.put(9, "foo")
        |> OrderedMap.put(8, "faz")

      assert "bar" == OrderedMap.get(map, 10)
    end
  end

  describe "to_list/1" do
    test "transoforms bst to ordered list" do
      map =
        OrderedMap.new()
        |> OrderedMap.put(10, "bar")
        |> OrderedMap.put(15, "faz")
        |> OrderedMap.put(13, "foo")

      assert [{10, "bar"}, {13, "foo"}, {15, "faz"}] == OrderedMap.to_list(map)
    end
  end
end
