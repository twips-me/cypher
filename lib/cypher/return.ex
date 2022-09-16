defmodule Cypher.Return do
  @moduledoc """
  RETURN clause
  """

  alias Cypher.{Expr, Query}

  @type t :: %__MODULE__{
    exprs: [{atom | nil, Expr.t}],
  }

  defstruct exprs: []

  @spec return(Macro.t) :: Macro.t
  @spec return(Macro.t, keyword) :: Macro.t
  defmacro return(ast, rest \\ []) do
    clauses =
      [compile(:return, ast, __CALLER__) | Query.compile_clauses(rest, __CALLER__)]
      |> reduce_consequetive_returns()
    quote do
      %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    end
  end

  @spec compile(:return, Macro.t, Macro.Env.t) :: t
  def compile(:return, ast, env) when not is_list(ast), do: compile(:return, [ast], env)
  def compile(:return, ast, env) do
    exprs =
      Enum.map(ast, fn
        {as, ast} when is_atom(as) -> {as, Expr.compile(ast, env)}
        ast -> {nil, Expr.compile(ast, env)}
      end)
    %__MODULE__{exprs: exprs}
  end

  defp reduce_consequetive_returns([%__MODULE__{} = a | [%__MODULE__{} = b | rest]]) do
    reduce_consequetive_returns([%{a | exprs: a.exprs ++ b.exprs} | rest])
  end
  defp reduce_consequetive_returns(clauses), do: clauses
end

defimpl Cypher.Entity, for: Cypher.Return do
  alias Cypher.{Entity, Return}

  @spec dump(Return.t) :: iodata
  def dump(%Return{exprs: []}), do: ""
  def dump(%Return{exprs: exprs}) do
    ["RETURN ", exprs |> Enum.map(&dump_expr/1) |> Enum.intersperse(",")]
  end

  defp dump_expr({nil, expr}), do: Entity.dump(expr)
  defp dump_expr({as, expr}), do: [Entity.dump(expr), " AS ", to_string(as)]
end
