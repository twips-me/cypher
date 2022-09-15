defmodule Cypher.Pattern do
  @moduledoc """
  Cypher patterns. Used in MATCH, CREATE, MERGE and WHERE clauses
  """

  alias Cypher.{Node, Relation}

  @type link :: :> | :< | :-
  @type t :: %__MODULE__{
    items: [Node.t | Relation.t | link],
    bindings: map,
  }

  defstruct items: [], bindings: %{}

  @links [:>, :<, :-]

  @spec compile(Macro.t, Macro.Env.t) :: t
  def compile({link, _, _} = ast, env) when link in @links do
    %__MODULE__{items: compile_items(ast, env)}
  end
  def compile(ast, env) when is_list(ast) do
    %__MODULE__{items: [Relation.compile(ast, env)]}
  end
  def compile(ast, env) when is_tuple(ast) do
    %__MODULE__{items: [Node.compile(ast, env)]}
  end

  defp compile_items({link, _, [a, b]}, env) when link in @links do
    compile_items(a, env) ++ [link] ++ compile_items(b, env)
  end
  defp compile_items(ast, env) when is_list(ast) do
    [Relation.compile(ast, env)]
  end
  defp compile_items(ast, env) when is_tuple(ast) do
    [Node.compile(ast, env)]
  end
end

defimpl Cypher.Entity, for: Cypher.Pattern  do
  alias Cypher.{Entity, Node, Pattern, Relation}

  @spec dump(Pattern.t) :: iodata
  def dump(%Pattern{items: items}) do
    dump_reducer(items)
  end

  defguardp is_link(l) when l in [:>, :<, :-]

  defp dump_reducer([]), do: []
  defp dump_reducer([%Node{} = node]), do: Entity.dump(node)
  defp dump_reducer([[_ | _] = result]), do: result
  defp dump_reducer([a | [:- | [%Relation{} = r | [l | [%Node{} = b | rest]]]]]) when is_link(l) do
    bin = [
      maybe_dump_node(a),
      "-",
      Entity.dump(r),
      dump_link(l),
      Entity.dump(b),
    ]
    dump_reducer([bin | rest])
  end
  defp dump_reducer([a | [l | [%Relation{} = r | [:- | [%Node{} = b | rest]]]]]) when is_link(l) do
    bin = [
      maybe_dump_node(a),
      dump_link(l),
      Entity.dump(r),
      "-",
      Entity.dump(b),
    ]
    dump_reducer([bin | rest])
  end
  defp dump_reducer([a | [l | [%Node{} = b | rest]]]) when is_link(l) do
    dump_reducer([[maybe_dump_node(a), dump_node_link(l), Entity.dump(b)] | rest])
  end

  defp maybe_dump_node(%Node{} = node), do: Entity.dump(node)
  defp maybe_dump_node([_ | _] = dumped), do: dumped

  defp dump_node_link(:-), do: "--"
  defp dump_node_link(:>), do: "-->"
  defp dump_node_link(:<), do: "<--"

  defp dump_link(:-), do: "-"
  defp dump_link(:>), do: "->"
  defp dump_link(:<), do: "<-"
end
