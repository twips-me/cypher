defmodule Cypher.OrderBy do
  @moduledoc """
  ORDER BY clause
  """

  alias Cypher.{Expr, Helpers}

  @type t :: %__MODULE__{
    exprs: [{:ASC | :DESC, Expr.t}],
  }

  @enforce_keys [:exprs]
  defstruct exprs: []

  @prefixes ~w[asc desc]a

  @spec compile(:order_by, Macro.t, Macro.Env.t) :: t
  def compile(:order_by, ast, env) when is_list(ast) do
    opts = [binding_compiler: &Helpers.field_binding_compiler/1]
    exprs = Enum.map(ast, fn
      {prefix, ast} when prefix in @prefixes -> {prefix, Expr.compile(ast, env, opts)}
      ast -> {:asc, Expr.compile(ast, env, opts)}
    end)
    %__MODULE__{exprs: exprs}
  end
  def compile(:order_by, ast, env), do: compile(:order_by, [ast], env)
end

defimpl Cypher.Entity, for: Cypher.OrderBy do
  alias Cypher.{Entity, OrderBy}

  @spec dump(OrderBy.t) :: iodata
  def dump(%OrderBy{exprs: []}), do: ""
  def dump(%OrderBy{exprs: exprs}) do
    ["ORDER BY ", exprs |> Enum.map(&dump_expr/1) |> Enum.intersperse(",")]
  end

  defp dump_expr({:asc, expr}), do: Entity.dump(expr)
  defp dump_expr({:desc, expr}), do: [Entity.dump(expr), " DESC"]
end
