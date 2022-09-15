defmodule Cypher.MatchTest do
  use ExUnit.Case

  alias Cypher.{Entity, Match, Node, Pattern, Query, Relation}

  import Match
  require Match

  describe "match/2" do
    test "compiles underliying pattern" do
      assert match(%{a}) == %Query{clauses: [%Match{
        patterns: [%Pattern{items: [%Node{var: :a}]}],
        var: nil,
        optional: false,
      }]}
    end

    test "compiles optional match" do
      assert optional_match(%{a}) == %Query{clauses: [%Match{
        patterns: [%Pattern{items: [%Node{var: :a}]}],
        var: nil,
        optional: true,
      }]}
    end

    test "reduces multiple matches" do
      assert match(%{a}, match: %{b}, match: %{c}, optional_match: %{d}) == %Query{clauses: [
        %Match{
          patterns: [
            %Pattern{items: [%Node{var: :a}]},
            %Pattern{items: [%Node{var: :b}]},
            %Pattern{items: [%Node{var: :c}]},
          ],
          var: nil,
          optional: false,
        },
        %Match{
          patterns: [%Pattern{items: [%Node{var: :d}]}],
          var: nil,
          optional: true,
        }
      ]}
    end

    test "compiles pattern with variable binding" do
      x = 10
      assert match(%{a: ^x}) == %Query{clauses: [%Match{patterns: [%Pattern{items: [%Node{properties: [a: 10]}]}]}]}
    end

    test "assigns path variable" do
      assert match(p = %{a}) == %Query{clauses: [%Match{var: :p, patterns: [%Pattern{items: [%Node{var: :a}]}]}]}
    end
  end

  describe "dump/2" do
    test "dumps to cypher MATCH clause" do
      result =
        %Query{clauses: [%Match{patterns: [%Pattern{items: [
          %Node{var: :a},
          :-,
          %Relation{var: :r},
          :>,
          %Node{var: :b},
        ]}]}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "MATCH (a)-[r]->(b)"
    end

    test "dumps to cypher OPTIONAL MATCH clause" do
      result =
        %Query{clauses: [%Match{
          patterns: [%Pattern{items: [%Node{var: :a}]}],
          optional: true,
        }]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "OPTIONAL MATCH (a)"
    end

    test "dumps cypher variable binding" do
      result =
        %Query{clauses: [%Match{
          patterns: [%Pattern{items: [%Node{var: :a}]}],
          var: :p,
        }]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "p=MATCH (a)"
    end

    test "dumps multiple patterns" do
      result =
        %Query{clauses: [%Match{patterns: [
          %Pattern{items: [%Node{var: :a}]},
          %Pattern{items: [%Node{var: :b}]},
        ]}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "MATCH (a),(b)"
    end
  end
end
