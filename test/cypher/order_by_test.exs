defmodule Cypher.OrderByTest do
  use ExUnit.Case

  alias Cypher.{Entity, Expr, OrderBy}

  import OrderBy

  describe "compile/3" do
    test "compiles one expression" do
      assert compile(:order_by, quote(do: a), __ENV__) == %OrderBy{exprs: [asc: %Expr{ast: {:variable, :a}}]}
    end

    test "compiles one expression in descending order" do
      assert compile(:order_by, quote(do: [desc: a]), __ENV__) == %OrderBy{exprs: [desc: %Expr{ast: {:variable, :a}}]}
    end

    test "compiles list of expressions" do
      assert compile(:order_by, quote(do: [a, b, c]), __ENV__) == %OrderBy{
        exprs: [
          asc: %Expr{ast: {:variable, :a}},
          asc: %Expr{ast: {:variable, :b}},
          asc: %Expr{ast: {:variable, :c}},
        ]
      }
    end

    test "compiles list of expressions in descending order" do
      assert compile(:order_by, quote(do: [desc: a, desc: b, desc: c]), __ENV__) == %OrderBy{
        exprs: [
          desc: %Expr{ast: {:variable, :a}},
          desc: %Expr{ast: {:variable, :b}},
          desc: %Expr{ast: {:variable, :c}},
        ]
      }
    end

    test "compiles list of expressions in mixed order" do
      assert compile(:order_by, quote(do: [asc: a, desc: b, asc: c]), __ENV__) == %OrderBy{
        exprs: [
          asc: %Expr{ast: {:variable, :a}},
          desc: %Expr{ast: {:variable, :b}},
          asc: %Expr{ast: {:variable, :c}},
        ]
      }
    end
  end

  describe "dump/2" do
    test "dumps to cypher ORDER BY clause" do
      result =
        %OrderBy{
          exprs: [
            asc: %Expr{ast: {:variable, :a}},
            desc: %Expr{ast: {:variable, :b}},
            asc: %Expr{ast: {:variable, :c}},
          ]
        }
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "ORDER BY a,b DESC,c"
    end
  end
end
