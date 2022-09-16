defmodule Cypher.Query do
  @moduledoc """
  Cypher query
  """

  alias Cypher.{Match, Return, Where}

  @type t :: %__MODULE__{
    clauses: [Match.t],
  }

  defstruct clauses: []

  @imports [
    {Match, match: 1, match: 2, optional_match: 1, optional_match: 2},
    {Return, return: 1, return: 2},
  ]

  @compilers [
    match: Match,
    optional_match: Match,
    return: Return,
    where: Where,
  ]

  @spec __using__(Macro.t) :: Macro.t
  defmacro __using__(_opts) do
    imports =
      @imports
      |> Enum.map(fn {module, functions} ->
        quote do
          import unquote(module), only: unquote(functions)
        end
      end)
    quote do
      unquote_splicing(imports)
    end
  end

  @spec imports() :: [{module, keyword}]
  def imports, do: @imports

  @spec compile_clauses(keyword, Macro.Env.t) :: list
  def compile_clauses(clauses, env) do
    Enum.map(clauses, & compile_clause(&1, env))
  end

  defp compile_clause({clause, ast}, env) do
    module = Keyword.fetch!(@compilers, clause)
    module.compile(clause, ast, env)
  end
end

defimpl Cypher.Entity, for: Cypher.Query do
  alias Cypher.{Entity, Query}

  @spec dump(Query.t) :: iodata
  def dump(%Query{clauses: clauses}) do
    Enum.map(clauses, &Entity.dump/1)
  end
end
