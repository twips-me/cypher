defmodule Cypher.MatchTest do
  use ExUnit.Case

  alias Cypher.{Entity, Match, MatchPattern, Node, Pattern, Query, Relation, Where}

  import Match
  require Match

  describe "match/2" do
    test "compiles underliying pattern" do
      assert match(%{a}) == %Query{clauses: [%Match{
        patterns: [%MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}}],
        optional: false,
      }]}
    end

    test "compiles optional match" do
      assert optional_match(%{a}) == %Query{clauses: [%Match{
        patterns: [%MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}}],
        optional: true,
      }]}
    end

    test "reduces multiple wheres" do
      assert match(%{a}, where: a.n > 1, where: a.x == "a") == %Query{clauses: [
        %Match{
          patterns: [%MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}}],
          optional: false,
        },
        %Where{
          expr: {:and, {:>, {:field, :a, [:n]}, 1}, {:==, {:field, :a, [:x]}, "a"}},
        }
      ]}
    end

    test "multiple matches" do
      assert match(%{a} | x = %{b} | y = %{c}) == %Query{clauses: [
        %Match{
          patterns: [
            %MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}},
            %MatchPattern{pattern: %Pattern{items: [%Node{var: :b}]}, var: :x},
            %MatchPattern{pattern: %Pattern{items: [%Node{var: :c}]}, var: :y},
          ],
          optional: false,
        }
      ]}
    end

    test "compiles pattern with variable binding" do
      x = 10
      assert match(%{a: ^x}) == %Query{clauses: [
        %Match{patterns: [%MatchPattern{pattern: %Pattern{items: [%Node{properties: [a: 10]}]}}]}
      ]}
    end

    test "assigns path variable" do
      assert match(p = %{a}) == %Query{clauses: [%Match{patterns: [
        %MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}, var: :p}
      ]}]}
    end
  end

  describe "dump/2" do
    test "dumps to cypher MATCH clause" do
      result =
        %Query{clauses: [%Match{patterns: [%MatchPattern{pattern: %Pattern{items: [
          %Node{var: :a},
          :-,
          %Relation{var: :r},
          :>,
          %Node{var: :b},
        ]}}]}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "MATCH (a)-[r]->(b)"
    end

    test "dumps to cypher OPTIONAL MATCH clause" do
      result =
        %Query{clauses: [%Match{
          patterns: [%MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}}],
          optional: true,
        }]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "OPTIONAL MATCH (a)"
    end

    test "dumps cypher variable binding" do
      result =
        %Query{clauses: [%Match{
          patterns: [%MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}, var: :p}],
        }]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "MATCH p=(a)"
    end

    test "dumps multiple patterns" do
      result =
        %Query{clauses: [%Match{patterns: [
          %MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}},
          %MatchPattern{pattern: %Pattern{items: [%Node{var: :b}]}, var: :x},
          %MatchPattern{pattern: %Pattern{items: [%Node{var: :c}]}, var: :y},
        ]}]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "MATCH (a),x=(b),y=(c)"
    end
  end
end
