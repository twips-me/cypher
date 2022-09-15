defmodule Cypher.Match do
  @moduledoc """
  MATCH clause
  """

  alias Cypher.{Pattern, Query}

  @type t :: %__MODULE__{
    patterns: [Pattern.t],
    var: atom | nil,
    optional: boolean,
  }

  defstruct patterns: [], var: nil, optional: false

  @spec match(Macro.t) :: Macro.t
  @spec match(Macro.t, keyword) :: Macro.t
  defmacro match(ast, rest \\ []) do
    clauses =
      [compile(ast, __CALLER__) | Query.compile_clauses(rest, __CALLER__)]
      |> reduce_consequetive_matches()
    quote do
      %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    end
  end

  @spec optional_match(Macro.t) :: Macro.t
  @spec optional_match(Macro.t, keyword) :: Macro.t
  defmacro optional_match(ast, rest \\ []) do
    clauses =
      [%{compile(ast, __CALLER__) | optional: true} | Query.compile_clauses(rest, __CALLER__)]
      |> reduce_consequetive_matches()
    quote do
      %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    end
  end

  @spec compile(Macro.t, Macro.Env.t) :: t
  def compile({:=, _, [{var, _, mod}, ast]}, env) when is_atom(var) and is_atom(mod) do
    %__MODULE__{var: var, patterns: [Pattern.compile(ast, env)]}
  end
  def compile(ast, env) do
    %__MODULE__{patterns: [Pattern.compile(ast, env)]}
  end

  defp reduce_consequetive_matches([%__MODULE__{optional: o} = a | [%__MODULE__{optional: o} = b | rest]]) do
    reduce_consequetive_matches([%{a | patterns: a.patterns ++ b.patterns} | rest])
  end
  defp reduce_consequetive_matches(clauses), do: clauses
end

defimpl Cypher.Entity, for: Cypher.Match do
  alias Cypher.{Entity, Match}

  @spec dump(Match.t) :: iodata
  def dump(%Match{patterns: patterns, var: var, optional: optional}) do
    [dump_var(var), dump_optional(optional), "MATCH ", patterns |> Enum.map(&Entity.dump/1) |> Enum.intersperse(",")]
  end

  defp dump_optional(true), do: "OPTIONAL "
  defp dump_optional(_), do: ""

  defp dump_var(nil), do: ""
  defp dump_var(var), do: [to_string(var), "="]
end
