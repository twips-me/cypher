defmodule Cypher.Match do
  @moduledoc """
  MATCH clause
  """

  alias Cypher.{Expr, MatchPattern, Pattern, Query, Where}

  @type t :: %__MODULE__{
    patterns: [Pattern.t],
    optional: boolean,
  }

  defstruct patterns: [], optional: false

  @spec match(Macro.t) :: Macro.t
  @spec match(Macro.t, keyword) :: Macro.t
  defmacro match(ast, rest \\ []) do
    clauses = compile_with_query(:match, ast, rest, __CALLER__)
    quote do
      %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    end
  end

  @spec optional_match(Macro.t) :: Macro.t
  @spec optional_match(Macro.t, keyword) :: Macro.t
  defmacro optional_match(ast, rest \\ []) do
    clauses = compile_with_query(:optional_match, ast, rest, __CALLER__)
    quote do
      %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    end
  end

  @spec compile(:match | :optional_match, Macro.t, Macro.Env.t) :: t
  def compile(clause, ast, env) do
    patterns = MatchPattern.compile(ast, env)
    %__MODULE__{patterns: patterns, optional: clause == :optional_match}
  end

  defp compile_with_query(clause, ast, rest, env) do
    rest = rest |> Query.compile_clauses(env) |> reduce_consequetive_wheres()
    [compile(clause, ast, env) | rest]
  end

  defp reduce_consequetive_wheres([%Where{} = a | [%Where{} = b | rest]]) do
    reduce_consequetive_wheres([%{a | expr: {:and, Expr.unwrap(a.expr), Expr.unwrap(b.expr)}} | rest])
  end
  defp reduce_consequetive_wheres(clauses), do: clauses
end

defimpl Cypher.Entity, for: Cypher.Match do
  alias Cypher.{Entity, Match}

  @spec dump(Match.t) :: iodata
  def dump(%Match{patterns: []}), do: ""
  def dump(%Match{patterns: patterns, optional: optional}) do
    [
      dump_optional(optional),
      "MATCH ",
      patterns |> Enum.map(&Entity.dump/1) |> Enum.intersperse(","),
    ]
  end

  defp dump_optional(true), do: "OPTIONAL "
  defp dump_optional(_), do: ""
end
