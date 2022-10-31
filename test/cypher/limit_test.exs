defmodule Cypher.LimitTest do
  use ExUnit.Case

  alias Cypher.{Entity, Expr, Limit}

  import Limit

  describe "compile/3" do
    test "compiles with variable" do
      assert compile(:limit, 10, __ENV__) == %Limit{expr: %Expr{ast: 10}}
    end

    test "compiles with binding" do
      assert compile(:limit, quote(do: ^var), __ENV__) == %Limit{expr: %Expr{ast: {:unquote, [], [{:var, [], __MODULE__}]}}}
    end
  end

  describe "dump/2" do
    test "dumps to cypher LIMIT clause" do
      result =
        %Limit{expr: %Expr{ast: 10}}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "LIMIT 10"
    end
  end
end
