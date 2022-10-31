defmodule Cypher.Query do
  @moduledoc """
  Cypher query
  """

  alias Cypher.{Create, Delete, Limit, Match, OrderBy, Return, Skip, Where}

  @type t :: %__MODULE__{
    clauses: [Match.t],
  }

  defstruct clauses: []

  @imports [
    {Create, create: 1, create: 2},
    {Match, match: 1, match: 2, optional_match: 1, optional_match: 2},
  ]

  @compilers [
    create: Create,
    delete: Delete,
    detach_delete: Delete,
    limit: Limit,
    match: Match,
    optional_match: Match,
    order_by: OrderBy,
    return: Return,
    skip: Skip,
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
    clauses
    |> Enum.map(&Entity.dump/1)
    |> Enum.intersperse(" ")
  end
end
