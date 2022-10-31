defmodule Cypher.SkipTest do
  use ExUnit.Case

  alias Cypher.{Entity, Expr, Skip}

  import Skip

  describe "compile/3" do
    test "compiles with variable" do
      assert compile(:skip, 7, __ENV__) == %Skip{expr: %Expr{ast: 7}}
    end

    test "compiles with binding" do
      assert compile(:skip, quote(do: ^var), __ENV__) == %Skip{expr: %Expr{ast: {:unquote, [], [{:var, [], __MODULE__}]}}}
    end
  end

  describe "dump/2" do
    test "dumps to cypher SKIP clause" do
      result =
        %Skip{expr: %Expr{ast: 5}}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "SKIP 5"
    end
  end
end
