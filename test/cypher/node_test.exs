defmodule Cypher.NodeTest do
  use ExUnit.Case

  alias Cypher.{Entity, Node}

  import Node

  describe "compile/2" do
    test "compiles `%{}` as an empty node" do
      assert compile(quote(do: %{}), __ENV__) == %Node{var: nil, label: nil, properties: []}
    end

    test "compiles `%{var}` as a node with binded variable" do
      assert compile(quote(do: %{var}), __ENV__) == %Node{var: :var, label: nil, properties: []}
    end

    test "refutes multiple variables binding like `%{a, b}`" do
      assert_raise CompileError, fn ->
        compile(quote(do: %{a, b}), __ENV__)
      end
    end

    test "compiles `%A{}` as a node with label A" do
      assert compile(quote(do: %A{}), __ENV__) == %Node{var: nil, label: A, properties: []}
    end

    test "compiles `%{a: 10}` as a node with property `a` with value 10" do
      assert compile(quote(do: %{a: 10}), __ENV__) == %Node{var: nil, label: nil, properties: [{:a, 10}]}
    end

    test "compiles `%{a: ^v}` as a node with property `a` binded to variable `v`" do
      assert compile(quote(do: %{a: ^v}), __ENV__) == %Node{
        var: nil,
        label: nil,
        properties: [{:a, {:unquote, [], [{:v, [], __MODULE__}]}}],
      }
    end

    test "compiles `%{a: 10, a: 20}` as a node with property `a` with value 10" do
      assert compile(quote(do: %{a: 10, a: 20}), __ENV__) == %Node{var: nil, label: nil, properties: [{:a, 10}]}
    end

    test "refutes invalid property definitions like `%{a: 1, b: self()}`" do
      assert_raise CompileError, ~r/Invalid property definition/, fn ->
        compile(quote(do: %{a: 1, b: self()}), __ENV__)
      end
    end

    test "compiles `%A{a}` as a node with binded variable `a` and label `A`" do
      assert compile(quote(do: %A{a}), __ENV__) == %Node{var: :a, label: A, properties: []}
    end

    test "compiles `%{a | b: 1}` as a node with binded variable `a` and property `b` with value 1" do
      assert compile(quote(do: %{a | b: 1}), __ENV__) == %Node{var: :a, label: nil, properties: [{:b, 1}]}
    end

    test "compiles `%A{b: 1}` as a node with label `A` and property `b` with value 1" do
      assert compile(quote(do: %A{b: 1}), __ENV__) == %Node{var: nil, label: A, properties: [{:b, 1}]}
    end

    test "compiles `%A{a | b: 1}` as a node with binded variable `a`, label `A` and property `b` with value 1" do
      assert compile(quote(do: %A{a | b: 1}), __ENV__) == %Node{var: :a, label: A, properties: [{:b, 1}]}
    end
  end

  describe "dump/2" do
    test "dumps empty node" do
      assert %Node{} |> Entity.dump() |> IO.iodata_to_binary() == "()"
    end

    test "dumps node with variable binding" do
      assert %Node{var: :a} |> Entity.dump() |> IO.iodata_to_binary() == "(a)"
    end

    test "dumps node with label" do
      assert %Node{label: A} |> Entity.dump() |> IO.iodata_to_binary() == "(:A)"
    end

    test "dumps node with properties" do
      result =
        %Node{properties: [{:a, 10}, {:b, "test"}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "({a:10,b:'test'})"
    end

    test "dumps node with variable binding and label" do
      assert %Node{var: :a, label: A} |> Entity.dump() |> IO.iodata_to_binary() == "(a:A)"
    end

    test "dumps node with variable binding and properties" do
      assert %Node{var: :a, properties: [{:x, 1}]} |> Entity.dump() |> IO.iodata_to_binary() == "(a{x:1})"
    end

    test "dumps node with label and properties" do
      assert %Node{label: A, properties: [{:x, 1}]} |> Entity.dump() |> IO.iodata_to_binary() == "(:A{x:1})"
    end

    test "dumps node with variable binding, label and properties" do
      result =
        %Node{var: :a, label: A, properties: [{:x, true}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "(a:A{x:true})"
    end
  end
end
