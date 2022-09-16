defmodule Cypher.Where do
  @moduledoc """
  WHERE clause
  """

  alias Cypher.Expr

  @type t :: %__MODULE__{
    expr: Expr.t,
  }

  @enforce_keys [:expr]
  defstruct expr: nil

  @spec compile(:where, Macro.t, Macro.Env.t) :: t
  def compile(:where, ast, env) do
    %__MODULE__{expr: Expr.compile(ast, env)}
  end
end

defimpl Cypher.Entity, for: Cypher.Where do
  alias Cypher.{Entity, Where}

  @spec dump(Where.t) :: iodata
  def dump(%Where{expr: expr}) do
    ["WHERE ", Entity.dump(expr)]
  end
end
