defmodule Cypher.Node do
  @moduledoc """
  Cypher node item

  Nodes are specified with Elixir map or struct syntax. Struct form used to specify node label.
  To bind node to a Cypher variable use update-map syntax. Also you can use `^x` syntax to
  bind Elixir `x` variable to properties

  Examples:

    %{}                     # => ()
    %User{}                 # => (:User)
    %User{var}              # => (var:User)
    %{var}                  # => (var)
    %{score: 10}            # => ({score: 10})
    %User{score: 10}        # => (:User{score: 10})
    x = 100
    %User{score: ^x}        # => (:User{score: 100})
    %{var | score: 10}      # => (var{score: 10})
    %User{var | score: ^x}  # => (var:User{score: 100})
  """

  alias Cypher.Helpers

  import Helpers

  @type t :: %__MODULE__{
    var: atom | nil,
    label: atom | nil,
    properties: [Helpers.property],
  }

  defstruct var: nil, label: nil, properties: []

  @spec compile(Macro.t, Macro.Env.t) :: any
  def compile({:%{}, _, []}, _env), do: %__MODULE__{}
  def compile({:%{}, _, [{var, _, mod}]}, _env) when is_atom(var) and is_atom(mod) do
    %__MODULE__{var: var}
  end
  def compile({:%{}, _, [{:|, _, [{var, _, mod}, [_ | _] = props]}]}, env) when is_atom(var) and is_atom(mod) do
    %__MODULE__{var: var, properties: compile_properties(props, env)}
  end
  def compile({:%{}, _, props}, env) when is_list(props) do
    %__MODULE__{properties: compile_properties(props, env)}
  end
  def compile({:%, _, [label, rest]}, env) do
    label = Macro.expand(label, env)
    %{compile(rest, env) | label: label}
  end
end

defimpl Cypher.Entity, for: Cypher.Node do
  alias Cypher.{Helpers, Node}

  import Helpers

  @spec dump(Node.t) :: iodata
  def dump(%Node{var: var, label: nil, properties: properties}) do
    ["(", dump_var(var), dump_properties(properties), ")"]
  end
  def dump(%Node{var: var, label: label, properties: properties}) do
    ["(", dump_var(var), ":", dump_label(label), dump_properties(properties), ")"]
  end

  defp dump_label(label) do
    str = label |> to_string()
    case str |> String.split(".", parts: 2) do
      ["Elixir", rest] -> rest
      _other -> str
    end
  end
end
