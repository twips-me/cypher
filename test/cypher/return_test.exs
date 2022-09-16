defmodule Cypher.ReturnTest do
  use ExUnit.Case

  alias Cypher.{Entity, Expr, Query, Return}

  import Return
  require Return

  describe "match/2" do
    test "compiles one expression" do
      assert return(a) == %Query{clauses: [%Return{exprs: [{nil, %Expr{ast: {:variable, :a}}}]}]}
    end

    test "compiles list of expressions" do
      assert return([a, b]) == %Query{clauses: [%Return{exprs: [
        {nil, %Expr{ast: {:variable, :a}}},
        {nil, %Expr{ast: {:variable, :b}}},
      ]}]}
    end

    test "compiles expressions with `AS` keyword syntax" do
      assert return([as_a: a, as_b: b]) == %Query{clauses: [%Return{exprs: [
        {:as_a, %Expr{ast: {:variable, :a}}},
        {:as_b, %Expr{ast: {:variable, :b}}},
      ]}]}
    end

    test "reduces multiple returns" do
      assert return(a, return: [b, as_c: c]) == %Query{clauses: [%Return{exprs: [
        {nil, %Expr{ast: {:variable, :a}}},
        {nil, %Expr{ast: {:variable, :b}}},
        {:as_c, %Expr{ast: {:variable, :c}}},
      ]}]}
    end
  end

  describe "dump/2" do
    test "dumps to cypher RETURN clause" do
      result =
        %Query{clauses: [%Return{exprs: [
          {nil, %Expr{ast: {:variable, :a}}},
          {nil, %Expr{ast: {:variable, :b}}},
          {:as_c, %Expr{ast: {:variable, :c}}},
        ]}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "RETURN a,b,c AS as_c"
    end
  end
end
