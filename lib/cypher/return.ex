defmodule Cypher.Return do
  @moduledoc """
  RETURN clause
  """

  alias Cypher.{Expr, Query}

  @type t :: %__MODULE__{
    exprs: [Expr.t],
  }

  defstruct exprs: []

  @spec return(Macro.t | [Macro.t]) :: Macro.t
  @spec return(Macro.t | [Macro.t], keyword) :: Macro.t
  defmacro return(ast, rest \\ []) do
    # clauses =
    #   [compile(ast, __CALLER__) | Query.compile_clauses(rest, __CALLER__)]
    #   |> reduce_consequetive_matches()
    # quote do
    #   %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    # end
  end

  # @spec compile(Macro.t, Macro.Env.t) :: t
  # def compile({:=, _, [{var, _, mod}, ast]}, env) when is_atom(var) and is_atom(mod) do
  #   %__MODULE__{var: var, patterns: [Pattern.compile(ast, env)]}
  # end
  # def compile(ast, env) do
  #   %__MODULE__{patterns: [Pattern.compile(ast, env)]}
  # end

  # defp reduce_consequetive_matches([%__MODULE__{optional: o} = a | [%__MODULE__{optional: o} = b | rest]]) do
  #   reduce_consequetive_matches([%{a | patterns: a.patterns ++ b.patterns} | rest])
  # end
  # defp reduce_consequetive_matches(clauses), do: clauses
end

defimpl Cypher.Entity, for: Cypher.Return do
  alias Cypher.{Entity, Return}

  @spec dump(Return.t) :: iodata
  def dump(%Return{exprs: exprs}) do
    ["RETURN ", exprs |> Enum.map(&Entity.dump/1) |> Enum.intersperse(",")]
  end
end
