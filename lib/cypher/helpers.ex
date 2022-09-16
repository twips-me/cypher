defmodule Cypher.Helpers do
  @moduledoc false

  @type kept_ast :: {:unquote, list, any}
  @type property :: {atom, atom | binary | number | kept_ast}

  @spec error(String.t, Macro.Env.t) :: none
  def error(msg, env) do
    raise CompileError, description: msg, file: Map.get(env, :file), line: Map.get(env, :line)
  end

  @spec compile_properties([Macro.t], Macro.Env.t) :: [property]
  def compile_properties(properties, env) do
    properties |> Enum.map(& compile_property(&1, env)) |> Enum.uniq_by(& elem(&1, 0))
  end

  @spec dump_var(atom | nil) :: binary
  def dump_var(nil), do: ""
  def dump_var(var), do: to_string(var)

  @spec dump_properties([property]) :: iodata
  def dump_properties([]), do: ""
  def dump_properties(properties) do
    bin = properties |> Enum.map(&dump_property/1) |> Enum.intersperse(",")
    ["{", bin, "}"]
  end

  @spec dump_literal(any) :: binary
  def dump_literal(v) when is_binary(v), do: ["'", v, "'"]
  def dump_literal(v), do: to_string(v)

  @spec keep_ast(Macro.t) :: kept_ast
  def keep_ast(ast), do: {:unquote, [], [ast]}

  @spec bind_var(Macro.t) :: kept_ast
  def bind_var({var, _meta, mod} = ast) when is_atom(var) and is_atom(mod) do
    keep_ast(ast)
  end

  defp compile_property({key, {:^, _, [{var, _, mod} = ast]}}, _env) when is_atom(var) and is_atom(mod) do
    {key, bind_var(ast)}
  end
  defp compile_property({key, v}, _env) when is_atom(v) or is_binary(v) or is_number(v) do
    {key, v}
  end
  defp compile_property(_, env) do
    error("Invalid property definition", env)
  end

  defp dump_property({k, v}), do: [to_string(k), ":", dump_literal(v)]
end
