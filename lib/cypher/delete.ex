defmodule Cypher.Delete do
  @moduledoc """
  DELETE clause
  """

  alias Cypher.Expr

  @type t :: %__MODULE__{
    exprs: [Expr.t],
    detach: boolean,
  }

  defstruct exprs: [], detach: false

  @spec compile(:delete, Macro.t, Macro.Env.t) :: t
  def compile(:delete, ast, env) do
    %__MODULE__{exprs: compile_ast(ast, env)}
  end
  def compile(:detach_delete, ast, env) do
    %__MODULE__{detach: true, exprs: compile_ast(ast, env)}
  end

  defp compile_ast(ast, env) when is_list(ast) do
    Enum.map(ast, & Expr.compile(&1, env))
  end
  defp compile_ast(ast, env), do: compile_ast([ast], env)
end

defimpl Cypher.Entity, for: Cypher.Delete do
  alias Cypher.{Entity, Delete}

  @spec dump(Delete.t) :: iodata
  def dump(%Delete{exprs: exprs, detach: detach}) do
    detach = if detach, do: "DETACH ", else: ""
    [detach, "DELETE ", exprs |> Enum.map(&Entity.dump/1) |> Enum.intersperse(",")]
  end
end
