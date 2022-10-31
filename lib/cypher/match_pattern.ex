defmodule Cypher.MatchPattern do
  @moduledoc """
  Internal part of pattern clause
  """

  alias Cypher.Pattern

  @type t :: %__MODULE__{
    pattern: Pattern.t,
    var: atom | nil,
  }

  @enforce_keys [:pattern]
  defstruct pattern: nil, var: nil

  @spec compile(Macro.t, Macro.Env.t) :: [t]
  def compile({:|, _, ast}, env) do
    ast
    |> Enum.map(& compile(&1, env))
    |> List.flatten()
  end
  def compile({:=, _, [{var, _, mod}, ast]}, env) when is_atom(var) and is_atom(mod) do
    [%__MODULE__{var: var, pattern: Pattern.compile(ast, env)}]
  end
  def compile(ast, env) do
    [%__MODULE__{pattern: Pattern.compile(ast, env)}]
  end
end

defimpl Cypher.Entity, for: Cypher.MatchPattern do
  alias Cypher.{Entity, MatchPattern}

  @spec dump(MatchPattern.t) :: iodata
  def dump(%MatchPattern{pattern: pattern, var: var}) do
    [
      dump_var(var),
      Entity.dump(pattern),
    ]
  end

  defp dump_var(nil), do: ""
  defp dump_var(var), do: [to_string(var), "="]
end
