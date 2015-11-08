defmodule Rubixer.Macros do
  import Rubixer.Worker

  defmacro ruby(worker, [do: block]) do
    code = to_ruby_string(block)
    quote do
      run_sync(unquote(worker), """
        #{unquote(code)}
      """)
    end
  end

  ### Conditionals ###
  def to_ruby_string({if_unless, _, [statement, [{:do, result} | else_block]]}) when if_unless in [:if, :unless] do
     """
     #{if_unless} #{to_ruby_string(statement)}
       #{to_ruby_string(result)}
     #{else_statement(else_block)}end
     """
  end
  def to_ruby_string({:cond, [],[[do: [first | statements_and_results]]] }) do
    """
    if #{arrow_conditional(first) |> to_ruby_string}
      #{arrow_result(first) |> to_ruby_string}
    #{elsif_statements(statements_and_results)}end
    """
  end

  ### Methods ###
  def to_ruby_string({{:., [], [module, method]}, _, params}) do
     "#{to_ruby_string(module)}.#{method}(#{Enum.map(params, &to_ruby_string/1) |> Enum.join(", ")})"
  end

  ### Modules ###
  def to_ruby_string({:__aliases__, _, [module]}) do
    "#{module}"
  end

  ### Assignment ###
  def to_ruby_string({:=, _, [lhs, rhs]}) do
    {matches, variables} = pattern(lhs, path: "", matches: [], vars: [])
    # IO.inspect matches
    # IO.inspect variables
    matches = matches
              |> Enum.reverse
              |> Enum.map(fn({:match, data, path})->
                "raise Rubixer::MatchError.new(_rubixer_) unless #{to_ruby_string(data)} == _rubixer_#{path}\n"
              end)
    variables = variables
                |> Enum.reverse
                |> Enum.map(fn({:path_var, path, var})->
                  "#{var} = _rubixer_#{path}\n"
                end)
    """
    _rubixer_ = #{to_ruby_string(rhs)}
    #{matches}#{variables}_rubixer_
    """
  end

  ### Primitives ###
  def to_ruby_string(i) when is_number(i), do: inspect(i)
  def to_ruby_string(s) when is_binary(s), do: inspect(s)
  def to_ruby_string(a) when is_atom(a), do: inspect(a)
  def to_ruby_string([{atom, v} | _rest] = keyword) when is_atom(atom) do
    Enum.into(keyword, %{})
    |> to_ruby_string
  end
  def to_ruby_string([{string, v} | _rest] = keyword) when is_binary(string) do
    Enum.into(keyword, %{})
    |> to_ruby_string
  end
  def to_ruby_string([:%{}, _, m]), do: to_ruby_hash(m)
  def to_ruby_string(m) when is_map(m), do: to_ruby_hash(m)
  def to_ruby_string({:{}, _, elements}), do: to_ruby_string(elements)
  def to_ruby_string(t) when is_tuple(t), do: to_ruby_string(Tuple.to_list(t))
  def to_ruby_string(c) when is_list(c) do
    "[#{Enum.map(c, &to_ruby_string/1) |> Enum.join(", ")}]"
  end

  ### Default Case ###
  def to_ruby_string(block) do
    "raise 'Unknown translation: #{inspect block}'"
  end

  # Helper functions
  defp to_ruby_hash(enumerable) do
    "{#{Enum.reduce(enumerable, [], fn({k,v}, acc)-> ["#{to_ruby_string(k)} => #{to_ruby_string(v)}" | acc] end) |> Enum.join(", ")}}"
  end

  defp arrow_conditional({:->, _, [[conditional], _result]}), do: conditional
  defp arrow_result({:->, _, [[_conditional], result]}), do: result

  defp elsif_statements(statements_and_results) do
    Enum.map(statements_and_results, fn(statement)->
      """
      elsif #{arrow_conditional(statement) |> to_ruby_string}
        #{arrow_result(statement) |> to_ruby_string}
      """
    end) |> Enum.join("")
  end
  defp else_statement([{:else, statement}]) do
    """
    else
      #{to_ruby_string(statement)}
    """
  end
  defp else_statement([]), do: ""

  defp pattern({var, a, b}, [path: path, matches: matches, vars: vars]) when is_atom(var) and is_list(a) and is_atom(b) do
    {matches, [{:path_var, path, to_string(var)} | vars]}
  end
  defp pattern([{:|, _, [first, tail]}], path: path, matches: matches, vars: vars, index: index) do
    {matches, vars} = pattern(first, path: "#{path}[#{index}]", matches: matches, vars: vars)
    pattern(tail, path: "#{path}[#{index + 1}..-1]", matches: matches, vars: vars)
  end
  defp pattern([{:|, _, [first, tail]}], path: path, matches: matches, vars: vars) do
    {matches, vars} = pattern(first, path: "#{path}[0]", matches: matches, vars: vars)
    pattern(tail, path: "#{path}[1..-1]", matches: matches, vars: vars)
  end
  defp pattern([var | rest], path: path, matches: matches, vars: vars) when length(rest) > 0 do
    pattern([var | rest], path: path, matches: matches, vars: vars, index: 0)
  end
  defp pattern([var | rest], path: path, matches: matches, vars: vars, index: index) when length(rest) > 0 do
    {matches, vars} = pattern(var, path: "#{path}[#{index}]", matches: matches, vars: vars)
    pattern(rest, path: path, matches: matches, vars: vars, index: index + 1)
  end
  defp pattern([var], path: path, matches: matches, vars: vars) do
    pattern([var], path: path, matches: matches, vars: vars, index: 0)
  end
  defp pattern([var], path: path, matches: matches, vars: vars, index: index) do
    pattern(var, path: "#{path}[#{index}]", matches: matches, vars: vars)
  end
  # 3 or more tuple elements
  defp pattern({:{}, _, elements}, path: path, matches: matches, vars: vars) do
    pattern(elements, path: path, matches: matches, vars: vars)
  end
  # 2 or less tuple elements
  defp pattern(tuple, path: path, matches: matches, vars: vars) when is_tuple(tuple) do
    Tuple.to_list(tuple)
    |> pattern(path: path, matches: matches, vars: vars)
  end
  defp pattern(anything, path: path, matches: matches, vars: vars) do
    {[{:match, anything, path} | matches], vars}
  end

  # defp raise_match_error_statement(lhs) when is_list(lhs) do
  #   Enum.map(lhs, &(match_error(&1, []))
  #   |> Enum.drop_while(&(!&1))
  #   |> Enum.join("\n")
  # end
  # defp raise_match_error_statement(lhs) do
  #   "raise Rubixer::MatchError.new(_rubixer_) unless #{to_ruby_string(lhs)} == _rubixer_"
  # end

end
