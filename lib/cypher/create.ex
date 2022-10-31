defmodule Cypher.Create do
  @moduledoc """
  CREATE clause
  """

  alias Cypher.{MatchPattern, Query}

  @type t :: %__MODULE__{patterns: [MatchPattern.t]}

  defstruct patterns: []

  @spec create(Macro.t) :: Macro.t
  @spec create(Macro.t, keyword) :: Macro.t
  defmacro create(ast, rest \\ []) do
    rest = Query.compile_clauses(rest, __CALLER__)
    clauses = [compile(:create, ast, __CALLER__) | rest]
    quote do
      %unquote(Query){clauses: unquote(Macro.escape(clauses, unquote: true))}
    end
  end

  @spec compile(:create, Macro.t, Macro.Env.t) :: t
  def compile(:create, ast, env) do
    %__MODULE__{patterns: MatchPattern.compile(ast, env)}
  end
end

defimpl Cypher.Entity, for: Cypher.Create do
  alias Cypher.{Entity, Create}

  @spec dump(Create.t) :: iodata
  def dump(%Create{patterns: []}), do: ""
  def dump(%Create{patterns: patterns}) do
    [
      "CREATE ",
      patterns |> Enum.map(&Entity.dump/1) |> Enum.intersperse(","),
    ]
  end
end
