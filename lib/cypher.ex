defmodule Cypher do
  @moduledoc """
  Ecto-like DSL for [Cypher](https://neo4j.com/docs/cypher-manual/current/) query language.
  """

  alias Cypher.{Entity, Query}

  @doc """
  Dumps a query into Cypher query as an iodata.
  """
  @spec dump(Query.t) :: iodata
  def dump(%Query{} = query), do: Entity.dump(query)

  @doc """
  Dumps a query into Cypher query as a binary.
  """
  @spec to_cypher(Query.t) :: binary
  def to_cypher(%Query{} = query), do: query |> dump() |> IO.iodata_to_binary()
end
