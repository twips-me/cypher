defmodule Cypher.Relation do
  @moduledoc """
  Cypher relation item

  Relations are specified with Elixir list syntax. To specify label just put `:LABEL` into
  list, to specify multiple labels, put `:LABEL_A | :LABEL_B`. To bind relation to a Cypher
  variable put variable name into list. Finally you can specify any number of properties
  with keyword-style syntax. Also you can use `^x` syntax to bind Elixir `x` variable to properties

  Examples:

    []                        # => []
    [:REL]                    # => [:REL]
    [var, :REL]               # => [var:REL]
    [var, :A | :B]            # => [var:A|B]
    [var]                     # => [var]
    [score: 10]               # => [{score: 10}]
    [:REL, score: 10]         # => [:REL{score: 10}]
    x = 100
    [:REL, score: ^x]         # => [:REL{score: 100}]
    [var, score: 10]          # => [var{score: 10}]
    [var, :A | :B, score: ^x] # => [var:A|B{score: 100}]
  """

  alias Cypher.Helpers

  import Helpers

  @type repeat_limit :: non_neg_integer | nil
  @type repeat :: {repeat_limit, repeat_limit}

  @type t :: %__MODULE__{
    var: atom | nil,
    labels: [atom | Helpers.kept_ast],
    properties: [Helpers.property],
    repeat: nil | repeat,
  }

  defstruct var: nil, labels: [], properties: [], repeat: nil

  @spec compile(Macro.t, Macro.Env.t) :: t
  def compile(statements, env) when is_list(statements) do
    compile_statements(statements, env)
  end

  defp compile_statements(statements, env) do
    {rel, rest} = Enum.reduce(statements, {%__MODULE__{}, []}, & compile_statement(&1, env, &2))
    %{rel | properties: rest |> Enum.reverse() |> compile_properties(env)}
  end

  @lbl_syms [:|, :^]

  # range: [_, a: 10] => [{a: 10}*]
  defp compile_statement({:_, _, m}, _env, {%{repeat: nil} = rel, rest}) when is_atom(m) do
    {%{rel | repeat: {nil, nil}}, rest}
  end
  defp compile_statement({:_, _, m}, env, _acc) when is_atom(m) do
    error("Only one repeat specifier supported", env)
  end
  # range: [_(1..10), a: 10] => [{a: 10}*1..10]
  defp compile_statement({:_, _, [{:.., _, _} = range]}, env, {%{repeat: nil} = rel, rest}) do
    {%{rel | repeat: compile_range(range, env)}, rest}
  end
  defp compile_statement({:_, _, [{:.., _, _}]}, env, _acc) do
    error("Only one repeat specifier supported", env)
  end
  # range: [_*_, a: 10] => [{a: 10}*]
  defp compile_statement({:*, _, [{:_, _, m}, {:_, _, m}]}, _env, {%{repeat: nil} = rel, rest}) when is_atom(m) do
    {%{rel | repeat: {nil, nil}}, rest}
  end
  defp compile_statement({:*, _, [{:_, _, m}, {:_, _, m}]}, env, _acc) when is_atom(m) do
    error("Only one repeat specifier supported", env)
  end
  # range: [_*_(1..10), a: 10] => [{a: 10}*1..10]
  defp compile_statement(
    {:*, _, [{:_, _, m}, {:_, _, [{:.., _, _} = range]}]},
    env,
    {%{repeat: nil} = rel, rest}
  ) when is_atom(m) do
    {%{rel | repeat: compile_range(range, env)}, rest}
  end
  defp compile_statement({:*, _, [{:_, _, m}, {:_, _, [{:.., _, _}]}]}, env, _acc) when is_atom(m) do
    error("Only one repeat specifier supported", env)
  end
  # variable: [r, a: 10] => [r{a: 10}]
  defp compile_statement({var, _, m}, _env, {%{var: nil} = rel, rest}) when is_atom(var) and is_atom(m) do
    {%{rel | var: var}, rest}
  end
  defp compile_statement({var, _, m}, env, _acc) when is_atom(var) and is_atom(m) do
    error("Only one variable binding supported", env)
  end
  # label: [:A, a: 10] => [:A{a: 10}]
  defp compile_statement(label, _env, {%{labels: []} = rel, rest}) when is_atom(label) do
    {%{rel | labels: [label]}, rest}
  end
  defp compile_statement(label, env, _acc) when is_atom(label) do
    error("Only one label definition supported", env)
  end
  # labels: [:A | :B, a: 10] => [:A|B{a: 10}]
  defp compile_statement({lbl_sym, _, _} = labels, env, {%{labels: []} = rel, rest}) when lbl_sym in @lbl_syms do
    {%{rel | labels: compile_labels(labels, env)}, rest}
  end
  defp compile_statement({lbl_sym, _, _}, env, _acc) when lbl_sym in @lbl_syms do
    error("Only one label definition supported", env)
  end
  defp compile_statement(other, _env, {rel, rest}) do
    {rel, [other | rest]}
  end

  defp compile_range({:.., _, [a, b]}, _env) when is_integer(a) and is_integer(b) and a < b, do: {a, b}
  defp compile_range({:.., _, [a, {:_, _, m}]}, _env) when is_integer(a) and is_atom(m), do: {a, nil}
  defp compile_range({:.., _, [{:_, _, m}, b]}, _env) when is_integer(b) and is_atom(m), do: {nil, b}
  defp compile_range({:.., _, [{:_, _, m}, {:_, _, m}]}, _env) when is_atom(m), do: {nil, nil}
  defp compile_range(_, env), do: error("Invalid repeat range specifier", env)

  defp compile_labels(label, _env) when is_atom(label), do: [label]
  defp compile_labels({:|, _, labels}, env), do: labels |> Enum.flat_map(& compile_labels(&1, env)) |> Enum.uniq()
  defp compile_labels({:^, _, [{var, _, mod} = ast]}, _env) when is_atom(var) and is_atom(mod), do: [bind_var(ast)]
  defp compile_labels(_, env), do: error("Invalid label definition", env)
end

defimpl Cypher.Entity, for: Cypher.Relation do
  alias Cypher.Relation

  import Cypher.Helpers

  @spec dump(Relation.t) :: iodata
  def dump(%Relation{var: var, labels: labels, properties: properties, repeat: repeat}) do
    ["[", dump_var(var), dump_labels(labels), dump_properties(properties), dump_repeat(repeat), "]"]
  end

  defp dump_labels([_ | _] = labels), do: [":" | labels |> Enum.map(&to_string/1) |> Enum.intersperse("|")]
  defp dump_labels(_), do: []

  defp dump_repeat(nil), do: []
  defp dump_repeat({nil, nil}), do: "*"
  defp dump_repeat({nil, b}), do: ["*..", to_string(b)]
  defp dump_repeat({a, nil}), do: ["*", to_string(a), ".."]
  defp dump_repeat({a, b}), do: ["*", to_string(a), "..", to_string(b)]
end
