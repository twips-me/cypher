defmodule Cypher.RelationTest do
  use ExUnit.Case

  alias Cypher.{Entity, Relation}

  import Relation

  describe "compile/2" do
    test "compiles `[]` as an empty relation" do
      assert compile(quote(do: []), __ENV__) == %Relation{var: nil, labels: [], properties: []}
    end

    test "compiles `[var]` as a relation with binded variable" do
      assert compile(quote(do: [var]), __ENV__) == %Relation{var: :var, labels: [], properties: []}
    end

    test "refutes multiple variables binding like `[a, b]`" do
      assert_raise CompileError, ~r/Only one variable binding supported/, fn ->
        compile(quote(do: [a, b]), __ENV__)
      end
    end

    test "compiles `[:LABEL]` as a relation with label LABEL" do
      assert compile(quote(do: [:LABEL]), __ENV__) == %Relation{var: nil, labels: [:LABEL], properties: []}
    end

    test "compiles `[:A | :B]` as a relation with labels A and B" do
      assert compile(quote(do: [:A | :B]), __ENV__) == %Relation{var: nil, labels: [:A, :B], properties: []}
    end

    test "compiles `[:A | :B | :A]` as a relation with labels A and B" do
      assert compile(quote(do: [:A | :B | :A]), __ENV__) == %Relation{var: nil, labels: [:A, :B], properties: []}
    end

    test "compiles `[:A | ^v]` as a relation with labels A and binded variable `v`" do
      assert compile(quote(do: [:A | ^v]), __ENV__) == %Relation{
        var: nil,
        labels: [:A, {:unquote, [], [{:v, [], __MODULE__}]}],
        properties: [],
      }
    end

    test "compiles `[:A | ^v | :A, ^v]` as a relation with labels A and binded variable `v`" do
      assert compile(quote(do: [:A | ^v | :A | ^v]), __ENV__) == %Relation{
        var: nil,
        labels: [:A, {:unquote, [], [{:v, [], __MODULE__}]}],
        properties: [],
      }
    end

    test "compiles `[^v]` as a relation with binded variable `v` as a label" do
      assert compile(quote(do: [^v]), __ENV__) == %Relation{
        var: nil,
        labels: [{:unquote, [], [{:v, [], __MODULE__}]}],
        properties: [],
      }
    end

    test "refutes non-atoms inside `|` label definition like `[:A | 1]`" do
      assert_raise CompileError, ~r/Invalid label definition/, fn ->
        compile(quote(do: [:A | 1]), __ENV__)
      end
    end

    test "refutes multiple label definitions like `[:A, :B]`" do
      assert_raise CompileError, ~r/Only one label definition supported/, fn ->
        compile(quote(do: [:A, :B]), __ENV__)
      end
    end

    test "refutes multiple label definitions like `[:A, :B | :C]`" do
      assert_raise CompileError, ~r/Only one label definition supported/, fn ->
        compile(quote(do: [:A, :B | :C]), __ENV__)
      end
    end

    test "refutes multiple label definitions like `[^a, ^b]`" do
      assert_raise CompileError, ~r/Only one label definition supported/, fn ->
        compile(quote(do: [^a, ^b]), __ENV__)
      end
    end

    test "compiles `[a: 10]` as a relation with property `a` with value 10" do
      assert compile(quote(do: [a: 10]), __ENV__) == %Relation{var: nil, labels: [], properties: [{:a, 10}]}
    end

    test "compiles `[a: ^v]` as a relation with property `a` binded to variable `v`" do
      assert compile(quote(do: [a: ^v]), __ENV__) == %Relation{
        var: nil,
        labels: [],
        properties: [{:a, {:unquote, [], [{:v, [], __MODULE__}]}}],
      }
    end

    test "compiles `[a: 10, a: 20]` as a relation with property `a` with value 10" do
      assert compile(quote(do: [a: 10, a: 20]), __ENV__) == %Relation{var: nil, labels: [], properties: [{:a, 10}]}
    end

    test "refutes invalid property definitions like `[a: 1, b: self()]`" do
      assert_raise CompileError, ~r/Invalid property definition/, fn ->
        compile(quote(do: [a: 1, b: self()]), __ENV__)
      end
    end

    test "compiles `[a, :A]` as a relation with binded variable `a` and label `A`" do
      assert compile(quote(do: [a, :A]), __ENV__) == %Relation{var: :a, labels: [:A], properties: []}
    end

    test "compiles `[a, b: 1]` as a relation with binded variable `a` and property `b` with value 1" do
      assert compile(quote(do: [a, b: 1]), __ENV__) == %Relation{var: :a, labels: [], properties: [b: 1]}
    end

    test "compiles `[:A, b: 1]` as a relation with label `A` and property `b` with value 1" do
      assert compile(quote(do: [:A, b: 1]), __ENV__) == %Relation{var: nil, labels: [:A], properties: [b: 1]}
    end

    test "compiles `[a, :A, b: 1]` as a relation with binded variable `a`, label `A` and property `b` with value 1" do
      assert compile(quote(do: [a, :A, b: 1]), __ENV__) == %Relation{var: :a, labels: [:A], properties: [b: 1]}
    end
  end

  describe "dump/2" do
    test "dumps empty relation" do
      assert %Relation{} |> Entity.dump() |> IO.iodata_to_binary() == "[]"
    end

    test "dumps relation with variable binding" do
      assert %Relation{var: :a} |> Entity.dump() |> IO.iodata_to_binary() == "[a]"
    end

    test "dumps relation with label" do
      assert %Relation{labels: [:A]} |> Entity.dump() |> IO.iodata_to_binary() == "[:A]"
    end

    test "dumps relation with multiple labels" do
      assert %Relation{labels: [:A, :B]} |> Entity.dump() |> IO.iodata_to_binary() == "[:A|B]"
    end

    test "dumps relation with properties" do
      result =
        %Relation{properties: [a: 10, b: "test"]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "[{a:10,b:'test'}]"
    end

    test "dumps relation with variable binding and label" do
      assert %Relation{var: :a, labels: [:A, :B]} |> Entity.dump() |> IO.iodata_to_binary() == "[a:A|B]"
    end

    test "dumps relation with variable binding and properties" do
      assert %Relation{var: :a, properties: [x: 1]} |> Entity.dump() |> IO.iodata_to_binary() == "[a{x:1}]"
    end

    test "dumps relation with label and properties" do
      result =
        %Relation{labels: [:A], properties: [x: 1]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "[:A{x:1}]"
    end

    test "dumps relation with variable binding, label and properties" do
      result =
        %Relation{var: :a, labels: [:A], properties: [x: true]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "[a:A{x:true}]"
    end
  end
end
