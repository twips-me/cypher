defmodule Cypher.Skip do
  @moduledoc """
  SKIP clause
  """

  alias Cypher.Expr

  @type t :: %__MODULE__{
    expr: Expr.t,
  }

  @enforce_keys [:expr]
  defstruct expr: nil

  @spec compile(:skip, Macro.t, Macro.Env.t) :: t
  def compile(:skip, ast, env) do
    %__MODULE__{expr: Expr.compile(ast, env)}
  end
end

defimpl Cypher.Entity, for: Cypher.Skip do
  alias Cypher.{Entity, Skip}

  @spec dump(Skip.t) :: iodata
  def dump(%Skip{expr: expr}) do
    ["SKIP ", Entity.dump(expr)]
  end
end
