defmodule Cypher.CreateTest do
  use ExUnit.Case

  alias Cypher.{Create, Entity, MatchPattern, Node, Pattern, Query, Relation}

  import Create
  require Create

  describe "create/2" do
    test "compiles underliying pattern" do
      assert create(%{a} - %{b}) == %Query{
        clauses: [
          %Create{
            patterns: [
              %MatchPattern{
                pattern: %Pattern{
                  items: [
                    %Node{var: :a, label: nil, properties: []},
                    :-,
                    %Node{var: :b, label: nil, properties: []},
                  ],
                  bindings: %{},
                },
                var: nil,
              },
            ],
          },
        ],
      }
    end

    test "compiles pattern with variable binding" do
      var = "test"
      assert create(%{prop: ^var}) == %Query{
        clauses: [
          %Create{
            patterns: [
              %MatchPattern{
                pattern: %Pattern{
                  items: [%Node{var: nil, label: nil, properties: [prop: "test"]}],
                  bindings: %{},
                },
              },
            ],
          },
        ],
      }
    end

    test "assigns variable" do
      assert create(var = %{a} - %{b}) == %Query{
        clauses: [
          %Create{
            patterns: [
              %MatchPattern{
                pattern: %Pattern{
                  items: [
                    %Node{var: :a, label: nil, properties: []},
                    :-,
                    %Node{var: :b, label: nil, properties: []},
                  ],
                  bindings: %{},
                },
                var: :var,
              },
            ],
          },
        ],
      }
    end
  end

  describe "dump/2" do
    test "dumps to cypher CREATE clause" do
      result =
        %Query{clauses: [%Create{
          patterns: [
            %MatchPattern{
              pattern: %Pattern{items: [
                %Node{var: :a},
                :-,
                %Relation{var: :r},
                :>,
                %Node{var: :b},
              ]},
            },
          ],
        }]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "CREATE (a)-[r]->(b)"
    end

    test "dumps cypher variable binding" do
      result =
        %Query{clauses: [%Create{
          patterns: [
            %MatchPattern{
              pattern: %Pattern{items: [%Node{var: :a}]},
              var: :var,
            },
          ],
        }]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "CREATE var=(a)"
    end

    test "dumps multiple patterns" do
      result =
        %Query{clauses: [
          %Create{patterns: [
            %MatchPattern{pattern: %Pattern{items: [%Node{var: :a}]}, var: nil},
            %MatchPattern{pattern: %Pattern{items: [%Node{var: :b}]}, var: :x},
            %MatchPattern{pattern: %Pattern{items: [%Node{var: :c}]}, var: :y},
          ]},
        ]}
        |> Entity.dump()
        |> IO.iodata_to_binary()
      assert result == "CREATE (a),x=(b),y=(c)"
    end
  end
end
