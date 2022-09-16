defmodule Cypher.ExprTest do
  use ExUnit.Case

  alias Cypher.{Entity, Expr, Node, Pattern, Relation}

  import Expr

  describe "compile/2" do
    test "compiles numbers" do
      assert compile(quote(do: 10), __ENV__) == %Expr{ast: 10}
      assert compile(quote(do: 1.5), __ENV__) == %Expr{ast: 1.5}
      assert compile(quote(do: 6.2e2), __ENV__) == %Expr{ast: 620.0}
      assert compile(quote(do: 0xff), __ENV__) == %Expr{ast: 255}
      assert compile(quote(do: 0o16), __ENV__) == %Expr{ast: 14}
      assert compile(quote(do: -100), __ENV__) == %Expr{ast: -100}
      assert compile(quote(do: +100), __ENV__) == %Expr{ast: 100}
    end

    test "compiles strings" do
      assert compile(quote(do: "str"), __ENV__) == %Expr{ast: "str"}
    end

    test "compiles booleans" do
      assert compile(quote(do: true), __ENV__) == %Expr{ast: true}
      assert compile(quote(do: false), __ENV__) == %Expr{ast: false}
    end

    test "compiles asterisk" do
      assert compile(quote(do: _), __ENV__) == %Expr{ast: :*}
      assert compile(quote(do: _*_), __ENV__) == %Expr{ast: :*}
    end

    test "compiles variables" do
      assert compile(quote(do: a), __ENV__) == %Expr{ast: {:variable, :a}}
    end

    test "compiles field access" do
      assert compile(quote(do: a.b), __ENV__) == %Expr{ast: {:field, :a, [:b]}}
      assert compile(quote(do: a.b.c), __ENV__) == %Expr{ast: {:field, :a, [:b, :c]}}
    end

    test "compiles dynamic field access" do
      assert compile(quote(do: a[b]), __ENV__) == %Expr{ast: {:dynamic_field, :a, {:variable, :b}}}
    end

    test "compiles list of expressions" do
      assert compile(quote(do: [1, "a"]), __ENV__) == %Expr{ast: [1, "a"]}
      assert compile(quote(do: [1, a]), __ENV__) == %Expr{ast: [1, {:variable, :a}]}
    end

    test "compiles function calls" do
      assert compile(quote(do: length(a)), __ENV__) == %Expr{ast: {:function, :length, [{:variable, :a}]}}
      assert compile(quote(do: nodes(a)), __ENV__) == %Expr{ast: {:function, :nodes, [{:variable, :a}]}}
      # TODO: find asterisk syntax: `count(*)`
    end

    test "compiles pattern path" do
      assert compile(quote(do: %{} - [r] > %{n}), __ENV__) == %Expr{ast: %Pattern{items: [
        %Node{},
        :-,
        %Relation{var: :r},
        :>,
        %Node{var: :n},
      ]}}

      assert compile(quote(do: %User{} - %{n}), __ENV__) == %Expr{ast: %Pattern{items: [
        %Node{label: User},
        :-,
        %Node{var: :n},
      ]}}
    end

    test "compiles %Cypher.Map as a map" do
      assert compile(quote(do: %Cypher.Map{a: 10, b: 20}), __ENV__) == %Expr{ast: %{a: 10, b: 20}}
      # TODO: working with maps: https://neo4j.com/docs/cypher-manual/current/syntax/maps/
    end

    test "compiles operators" do
      assert compile(quote(do: a + 1), __ENV__) == %Expr{ast: {:+, {:variable, :a}, 1}}
      assert compile(quote(do: a < 10), __ENV__) == %Expr{ast: {:<, {:variable, :a}, 10}}
      assert compile(quote(do: a.prop = "str"), __ENV__) == %Expr{ast: {:=, {:field, :a, [:prop]}, "str"}}
      assert compile(quote(do: length(p) > 10), __ENV__) == %Expr{
        ast: {:>, {:function, :length, [{:variable, :p}]}, 10},
      }
      assert compile(quote(do: not is_nil(a.name)), __ENV__) == %Expr{ast: {:is_not_nil, {:field, :a, [:name]}}}
    end

    test "compiles exists operator" do
      assert compile(quote(do: exists(1)), __ENV__) == %Expr{ast: {:exists, {:unquote, [], [1]}}}
    end

    test "compiles regexp operator" do
      assert compile(quote(do: a =~ "t.*"), __ENV__) == %Expr{ast: {:=~, {:variable, :a}, "t.*"}}
    end

    test "compiles starts_with operator" do
      assert compile(quote(do: starts_with(a.name, "John")), __ENV__) == %Expr{
        ast: {:starts_with, {:field, :a, [:name]}, "John"},
      }
    end

    test "compiles ends_with operator" do
      assert compile(quote(do: ends_with(a.name, "John")), __ENV__) == %Expr{
        ast: {:ends_with, {:field, :a, [:name]}, "John"},
      }
    end

    # TODO: CASE operator
  end

  describe "dump/2" do
    test "dumps numbers" do
      assert %Expr{ast: 10} |> Entity.dump() |> IO.iodata_to_binary() == "10"
      assert %Expr{ast: 1.5} |> Entity.dump() |> IO.iodata_to_binary() == "1.5"
      assert %Expr{ast: -100} |> Entity.dump() |> IO.iodata_to_binary() == "-100"
    end

    test "dumps strings" do
      assert %Expr{ast: "str"} |> Entity.dump() |> IO.iodata_to_binary() == "'str'"
    end

    test "dumps booleans" do
      assert %Expr{ast: true} |> Entity.dump() |> IO.iodata_to_binary() == "true"
      assert %Expr{ast: false} |> Entity.dump() |> IO.iodata_to_binary() == "false"
    end

    test "dumps asteris" do
      assert %Expr{ast: :*} |> Entity.dump() |> IO.iodata_to_binary() == "*"
    end

    test "dumps cypher variables" do
      assert %Expr{ast: {:variable, :a}} |> Entity.dump() |> IO.iodata_to_binary() == "a"
    end

    test "dumps field access" do
      assert %Expr{ast: {:field, :a, [:b]}} |> Entity.dump() |> IO.iodata_to_binary() == "a.b"
      assert %Expr{ast: {:field, :a, [:b, :c]}} |> Entity.dump() |> IO.iodata_to_binary() == "a.b.c"
    end

    test "dumps dynamic field access" do
      result =
        %Expr{ast: {:dynamic_field, :a, {:+, {:variable, :x}, 1}}}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "a[x+1]"
    end

    test "dumps a list of expressions" do
      result =
        %Expr{ast: [{:variable, :a}, 1]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "[a,1]"
    end

    test "dumps a function calls" do
      result =
        %Expr{ast: {:function, :length, [{:variable, :a}]}}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "length(a)"
    end

    test "dumps a pattern paths" do
      result =
        %Expr{ast: %Pattern{items: [
          %Node{label: User},
          :-,
          %Node{var: :n},
        ]}}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(:User)--(n)"
    end

    test "dumps operators with two arguments" do
      assert %Expr{ast: {:=, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x=1"
      assert %Expr{ast: {:+, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x+1"
      assert %Expr{ast: {:*, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x*1"
      assert %Expr{ast: {:%, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x%1"
      assert %Expr{ast: {:/, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x/1"
      assert %Expr{ast: {:<>, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x<>1"
      assert %Expr{ast: {:<=, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x<=1"
      assert %Expr{ast: {:>=, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x>=1"
      assert %Expr{ast: {:==, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x=1"
      assert %Expr{ast: {:=~, {:variable, :x}, "a"}} |> Entity.dump() |> IO.iodata_to_binary() == "x=~'a'"
      assert %Expr{ast: {:<, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x<1"
      assert %Expr{ast: {:>, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x>1"
      assert %Expr{ast: {:-, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x-1"
      assert %Expr{ast: {:and, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x AND 1"
      assert %Expr{ast: {:or, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x OR 1"
      assert %Expr{ast: {:xor, {:variable, :x}, 1}} |> Entity.dump() |> IO.iodata_to_binary() == "x XOR 1"
      assert %Expr{ast: {:in, {:variable, :x}, [1, 2]}} |> Entity.dump() |> IO.iodata_to_binary() == "x IN [1,2]"
    end

    test "dumps unary operators" do
      assert %Expr{ast: {:not, {:variable, :x}}} |> Entity.dump() |> IO.iodata_to_binary() == "NOT x"
      assert %Expr{ast: {:is_nil, {:variable, :x}}} |> Entity.dump() |> IO.iodata_to_binary() == "x IS NULL"
      assert %Expr{ast: {:is_not_nil, {:variable, :x}}} |> Entity.dump() |> IO.iodata_to_binary() == "x IS NOT NULL"
    end

    # TODO: exists test
    # test "dumps exists subquery" do
    # end

    test "dumps starts_with and ends_with" do
      assert %Expr{ast: {:starts_with, {:variable, :x}, "a"}} |> Entity.dump() |> IO.iodata_to_binary() == "x STARTS WITH 'a'"
      assert %Expr{ast: {:ends_with, {:variable, :x}, "a"}} |> Entity.dump() |> IO.iodata_to_binary() == "x ENDS WITH 'a'"
    end
  end
end
