defmodule Cypher.DeleteTest do
  use ExUnit.Case

  alias Cypher.{Delete, Entity, Expr}

  import Delete

  describe "compile/3" do
    test "compiles one expression" do
      assert compile(:delete, quote(do: node), __ENV__) == %Delete{
        exprs: [%Expr{ast: {:variable, :node}}],
        detach: false
      }
    end

    test "compiles one expression with detach" do
      assert compile(:detach_delete, quote(do: node), __ENV__) == %Delete{
        exprs: [%Expr{ast: {:variable, :node}}],
        detach: true
      }
    end

    test "compiles list of expressions" do
      assert compile(:delete, quote(do: [node1, node2]), __ENV__) == %Delete{
        exprs: [
          %Expr{ast: {:variable, :node1}},
          %Expr{ast: {:variable, :node2}}
        ],
        detach: false
      }
    end

    test "compiles list of expressions with detach" do
      assert compile(:detach_delete, quote(do: [node1, node2]), __ENV__) == %Delete{
        exprs: [
          %Expr{ast: {:variable, :node1}},
          %Expr{ast: {:variable, :node2}}
        ],
        detach: true
      }
    end
  end

  describe "dump/2" do
    test "dumps to cypher DELETE clause" do
      result =
        %Delete{
          exprs: [
            %Expr{ast: {:variable, :node1}},
            %Expr{ast: {:variable, :node2}}
          ],
          detach: false
        }
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "DELETE node1,node2"
    end

    test "dumps to cypher DETACH DELETE clause" do
      result =
        %Delete{
          exprs: [
            %Expr{ast: {:variable, :node1}},
            %Expr{ast: {:variable, :node2}}
          ],
          detach: true
        }
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "DETACH DELETE node1,node2"
    end
  end
end
