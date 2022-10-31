defmodule Cypher.Limit do
  @moduledoc """
  LIMIT clause
  """

  alias Cypher.Expr

  @type t :: %__MODULE__{
    expr: Expr.t,
  }

  @enforce_keys [:expr]
  defstruct expr: nil

  @spec compile(:limit, Macro.t, Macro.Env.t) :: t
  def compile(:limit, ast, env) do
    %__MODULE__{expr: Expr.compile(ast, env)}
  end
end

defimpl Cypher.Entity, for: Cypher.Limit do
  alias Cypher.{Entity, Limit}

  @spec dump(Limit.t) :: iodata
  def dump(%Limit{expr: expr}) do
    ["LIMIT ", Entity.dump(expr)]
  end
end
