defmodule Cypher.PatternTest do
  use ExUnit.Case

  alias Cypher.{Entity, Node, Pattern, Relation}

  import Pattern

  describe "compile/2" do
    test "compiles `%{}` as a pattern with one node" do
      assert %Pattern{items: [%Node{var: nil}]} = compile(quote(do: %{}), __ENV__)
    end

    test "compiles `%{a}` as a pattern with one node" do
      assert %Pattern{items: [%Node{var: :a}]} = compile(quote(do: %{a}), __ENV__)
    end

    test "compiles `%{a} > %{b}` as a pattern with two nodes" do
      assert %Pattern{items: [%Node{var: :a}, :>, %Node{var: :b}]} = compile(quote(do: (%{a} > %{b})), __ENV__)
    end

    test "compiles `%{a} > %{b} < %{c}` as a pattern with three nodes" do
      assert %Pattern{items: [
        %Node{var: :a},
        :>,
        %Node{var: :b},
        :<,
        %Node{var: :c},
      ]} = compile(quote(do: (%{a} > %{b} < %{c})), __ENV__)
    end

    test "compiles `[]` as a pattern with relation" do
      assert %Pattern{items: [%Relation{var: nil}]} = compile(quote(do: []), __ENV__)
    end

    test "compiles `[r]` as a pattern with relation" do
      assert %Pattern{items: [%Relation{var: :a}]} = compile(quote(do: [a]), __ENV__)
    end

    test "compiles `%{a} - [r] > %{b}` as a pattern with two nodes and relation" do
      assert %Pattern{items: [
        %Node{var: :a},
        :-,
        %Relation{var: :r},
        :>,
        %Node{var: :b},
      ]} = compile(quote(do: (%{a} - [r] > %{b})), __ENV__)
    end
  end

  describe "dump/2" do
    test "dumps single node" do
      assert %Pattern{items: [%Node{var: :a}]} |> Entity.dump() |> IO.iodata_to_binary() == "(a)"
    end

    test "dumps two linked nodes" do
      result =
        %Pattern{items: [%Node{var: :a}, :-, %Node{var: :b}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)--(b)"

      result =
        %Pattern{items: [%Node{var: :a}, :>, %Node{var: :b}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)-->(b)"

      result =
        %Pattern{items: [%Node{var: :a}, :<, %Node{var: :b}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)<--(b)"
    end

    test "dumps many linked nodes" do
      result =
        %Pattern{items: [%Node{var: :a}, :-, %Node{var: :b}, :>, %Node{var: :c}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)--(b)-->(c)"

      result =
        %Pattern{items: [%Node{var: :a}, :>, %Node{var: :b}, :<, %Node{var: :c}, :-, %Node{var: :d}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)-->(b)<--(c)--(d)"
    end

    test "dumps two nodes linked with relation" do
      result =
        %Pattern{items: [%Node{var: :a}, :-, %Relation{var: :r}, :>, %Node{var: :b}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)-[r]->(b)"
    end

    test "dumps many nodes linked with relation" do
      result =
        %Pattern{items: [
          %Node{var: :a},
          :-,
          %Relation{var: :r1},
          :>,
          %Node{var: :b},
          :<,
          %Relation{var: :r2},
          :-,
          %Node{var: :c},
        ]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)-[r1]->(b)<-[r2]-(c)"
    end

    test "dumps many nodes linked with relation mixed with direct node links" do
      result =
        %Pattern{items: [
          %Node{var: :a},
          :-,
          %Relation{var: :r1},
          :>,
          %Node{var: :b1},
          :-,
          %Node{var: :b2},
          :<,
          %Relation{var: :r2},
          :-,
          %Node{var: :c},
        ]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a)-[r1]->(b1)--(b2)<-[r2]-(c)"
    end
  end
end
