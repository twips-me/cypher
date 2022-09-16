defmodule Cypher.Expr do
  @moduledoc """
  Cypher expressions

  ### operators mapping

  elixir|cypher
  ------|------
  A ++ B | A += B
  pow(A, B) | A ^ B
  xor(A, B) | A xor B
  """

  alias Cypher.Pattern

  import Cypher.Helpers

  @type t :: %__MODULE__{
    ast: any,
  }

  defstruct ast: nil

  @spec compile(Macro.t, Macro.Env.t) :: t
  def compile(ast, env) do
    %__MODULE__{ast: compile_ast(ast, env)}
  end

  @spec unwrap(t) :: any
  def unwrap(%__MODULE__{ast: ast}), do: ast

  @unary_func_ops ~w[distinct is_nil not exists]
  @binary_func_ops ~w[starts_with ends_with contains and or = + ++ * % / pow xor in <> <= >= =~ ==]a
  @maybe_link_ops ~w[< > -]a

  defp compile_ast(x, _env) when is_number(x) or is_boolean(x) or is_binary(x), do: x
  defp compile_ast({:-, _, [n]}, _env) when is_number(n), do: -n
  defp compile_ast({:+, _, [n]}, _env) when is_number(n), do: n
  defp compile_ast({:__block__, _, [ast]}, env), do: compile_ast(ast, env)
  defp compile_ast({:%, _, [label, {:%{}, _, fields}]}, env) when is_list(fields) do
    if Macro.expand(label, env) != Cypher.Map or not Keyword.keyword?(fields) do
      error("Invalid node usage in expression", env)
    end
    Enum.into(fields, %{})
  end
  defp compile_ast({:_, _, m}, _env) when is_atom(m), do: :*
  defp compile_ast({:*, _, [{:_, _, m}, {:_, _, m}]}, _env) when is_atom(m), do: :*
  defp compile_ast({var, _, m}, _env) when is_atom(var) and is_atom(m), do: {:variable, var}
  defp compile_ast({:exists, _, [ast]}, _env) do
    {:exists, keep_ast(ast)}
  end
  defp compile_ast({:not, _, [{:is_nil, _, [ast]}]}, env) do
    {:is_not_nil, compile_ast(ast, env)}
  end
  defp compile_ast({op, _, [ast]}, env) when op in @unary_func_ops do
    {op, compile_ast(ast, env)}
  end
  defp compile_ast({op, _, [a, b]} = ast, env) when op in @maybe_link_ops do
    if is_node?(a, env) or is_node?(b, env) do
      Pattern.compile(ast, env)
    else
      {op, compile_ast(a, env), compile_ast(b, env)}
    end
  end
  defp compile_ast({op, _, [a, b]}, env) when op in @binary_func_ops do
    {op, compile_ast(a, env), compile_ast(b, env)}
  end
  defp compile_ast({fun, _, args}, env) when is_atom(fun) and is_list(args) do
    {:function, fun, Enum.map(args, & compile_ast(&1, env))}
  end
  defp compile_ast({{:., _, [Access, :get]}, _, [{var, _, mod}, ast]}, env) when is_atom(var) and is_atom(mod) do
    {:dynamic_field, var, compile_ast(ast, env)}
  end
  defp compile_ast({{:., _, [_, _]}, _, _} = ast, _env) do
    compile_field_access(ast, [])
  end
  defp compile_ast(ast, env) when is_list(ast), do: Enum.map(ast, & compile_ast(&1, env))

  defp compile_field_access({{:., _, [a, b]}, _, _}, path) when is_atom(b) do
    compile_field_access(a, [b | path])
  end
  defp compile_field_access({var, _, mod}, path) when is_atom(var) and is_atom(mod) do
    {:field, var, path}
  end

  defp is_node?({:%{}, _, _}, _env), do: true
  defp is_node?({:%, _, [label, {:%{}, _, _}]}, env), do: Macro.expand(label, env) != Cypher.Map
  defp is_node?(_ast, _env), do: false
end

defimpl Cypher.Entity, for: Cypher.Expr do
  alias Cypher.{Helpers, Entity, Expr}

  import Helpers

  @spec dump(Expr.t) :: iodata
  def dump(%Expr{ast: ast}) do
    dump_ast(ast)
  end

  @two_sides_ops ~w[= + * % / <> <= >= =~ < > -]a
  @two_sides_spaced_ops ~w[and or xor in]a

  defp dump_ast(n) when is_number(n) or is_boolean(n) or is_binary(n), do: dump_literal(n)
  defp dump_ast(:*), do: "*"
  defp dump_ast({:variable, var}), do: to_string(var)
  defp dump_ast({:field, var, fields}), do: [var | fields] |> Enum.map(&to_string/1) |> Enum.intersperse(".")
  defp dump_ast({:dynamic_field, var, ast}) do
    [to_string(var), "[", dump_ast(ast), "]"]
  end
  defp dump_ast({:not, a}) do
    ["NOT ", dump_ast(a)]
  end
  defp dump_ast({:is_nil, a}) do
    [dump_ast(a), " IS NULL"]
  end
  defp dump_ast({:is_not_nil, a}) do
    [dump_ast(a), " IS NOT NULL"]
  end
  defp dump_ast({:++, a, b}) do
    [dump_ast(a), "+=", dump_ast(b)]
  end
  defp dump_ast({:==, a, b}) do
    [dump_ast(a), "=", dump_ast(b)]
  end
  defp dump_ast({:pow, a, b}) do
    [dump_ast(a), "^", dump_ast(b)]
  end
  defp dump_ast({:starts_with, a, b}) do
    [dump_ast(a), " STARTS WITH ", dump_ast(b)]
  end
  defp dump_ast({:ends_with, a, b}) do
    [dump_ast(a), " ENDS WITH ", dump_ast(b)]
  end
  defp dump_ast({op, a, b}) when op in @two_sides_spaced_ops do
    [dump_ast(a), " ", op |> to_string() |> String.upcase(), " ", dump_ast(b)]
  end
  defp dump_ast({op, a, b}) when op in @two_sides_ops do
    [dump_ast(a), to_string(op), dump_ast(b)]
  end
  defp dump_ast({:function, name, args}) do
    [to_string(name), "(", args |> Enum.map(&dump_ast/1) |> Enum.intersperse(","), ")"]
  end
  defp dump_ast(list) when is_list(list) do
    ["[", list |> Enum.map(&dump_ast/1) |> Enum.intersperse(","), "]"]
  end
  defp dump_ast(other), do: Entity.dump(other)
end
