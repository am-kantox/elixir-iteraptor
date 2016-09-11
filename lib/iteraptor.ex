defmodule Iteraptor do
  @joiner "."

  @doc """
    iex> [:a, 42] |> Iteraptor.to_flatmap
    %{"0": :a, "1": 42}

    iex> %{a: 42} |> Iteraptor.to_flatmap
    %{a: 42}

    iex> %{a: 42, b: 42} |> Iteraptor.to_flatmap
    %{a: 42, b: 42}

    iex> %{a: %{b: 42}, d: 42} |> Iteraptor.to_flatmap
    %{"a.b": 42, d: 42}

    iex> %{a: [:b, 42], d: 42} |> Iteraptor.to_flatmap
    %{"a.0": :b, "a.1": 42, d: 42}

    iex> %{a: %{b: [:c, 42]}, d: 42} |> Iteraptor.to_flatmap
    %{"a.b.0": :c, "a.b.1": 42, d: 42}

    iex> %{a: %{b: 42}} |> Iteraptor.to_flatmap
    %{"a.b": 42}

    iex> %{a: %{b: %{c: 42}}} |> Iteraptor.to_flatmap
    %{"a.b.c": 42}

    iex> %{a: %{b: %{c: 42}}, d: 42} |> Iteraptor.to_flatmap
    %{"a.b.c": 42, d: 42}

    iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
    %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
  """

  def to_flatmap(input, joiner \\ @joiner) when is_map(input) or is_list(input) do
    process(input, joiner)
  end

  @doc """
    iex> %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42} |> Iteraptor.from_flatmap
    %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}
  """
  def from_flatmap(input, joiner \\ @joiner) when is_map(input) do
    unprocess(input, joiner)
  end

  @doc """
    iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(fn {k, v} -> IO.inspect({k, v}) end)
    %{"a.b.c": 42}
  """
  def each(input, joiner \\ @joiner, fun) do
    unless is_function(fun, 1), do: raise "Function or arity fun/1 is required"
    process(input, joiner, "", %{}, fun)
  end

  ##############################################################################

  defp process(input, joiner, prefix \\ "", acc \\ %{}, fun \\ nil)

  ### -----------------------------------------------------------------------###

  defp process(input, joiner, prefix, acc, fun) when is_map(input) do
    input |> Enum.reduce(acc, fn({k, v}, memo) ->
      prefix = join(prefix, k, joiner)
      if is_map(v) or is_list(v) do
        process(v, joiner, prefix, memo, fun)
      else
        unless is_nil(fun), do: fun.({prefix, v})
        Map.put memo, prefix, v
      end
    end)
  end

  defp process(input, joiner, prefix, acc, fun) when is_list(input) do
    input
      |> Enum.with_index
      |> Enum.map(fn({k, v}) -> {v, k} end)
      |> Enum.into(%{})
      |> process(joiner, prefix, acc, fun)
  end

  ##############################################################################

  defp unprocess(input, joiner, fun \\ nil)

  ### -----------------------------------------------------------------------###

  defp unprocess(input, joiner, fun) when is_map(input) do
    acc = if quacks_as_list(input, joiner), do: [], else: %{}

  end

  ##############################################################################

  defp join(l, r, joiner \\ @joiner)

  defp join(l, "", _) do
    String.to_atom(to_string(l))
  end

  defp join("", r, _) do
    String.to_atom(to_string(r))
  end

  defp join(l, r, joiner) do
    String.to_atom(to_string(l) <> joiner <> to_string(r))
  end

  ##############################################################################

  @doc """
    iex> %{} |> Iteraptor.put_or_update(".", "a.b.c", 42)
    %{a: %{b: %{c: 42}}}

    iex> %{} |> Iteraptor.put_or_update(".", "a.b.c", 42)
    ...>     |> Iteraptor.put_or_update(".", "a.b.d", 42)
    %{a: %{b: %{c: 42, d: 42}}}

    iex> %{} |> Iteraptor.put_or_update(".", "a.b.c", 42)
    ...>     |> Iteraptor.put_or_update(".", "a.b.d", 42)
    ...>     |> Iteraptor.put_or_update(".", "a.e", 42)
    %{a: %{b: %{c: 42, d: 42}, e: 42}}
  """
  def put_or_update(input, joiner, prefix, value) when is_map(input) do
    case prefix |> String.split(joiner, parts: 2) do
      [key, rest] ->
        {_, target} = input |> Map.get_and_update(join(key, ""), fn current ->
          old = case current do
            nil -> %{}
            _ -> current
          end
          {current, old |> put_or_update(joiner, rest, value)}
        end)
        target
      [key] ->
        input |> Map.put(join(key, ""), value)
    end
  end

  defp put_or_update(input, acc, joiner, key, value) when is_list(acc) do

  end

  ##############################################################################

  defp parse_key(key, joiner, prefix) do
    k = to_string(key)
        |> String.split(joiner)
        |> Enum.at((prefix |> String.split(joiner) |> Enum.count) - 1)
    try do
      k |> String.to_integer
    rescue
      ArgumentError -> k
    end
  end

  ##############################################################################

  defp filter_keys(input, prefix) do
    case prefix do
      "" -> input
      _ -> Enum.filter(fn e -> e |> to_string |> String.starts_with?(to_string(prefix)) end)
    end
  end

  defp quacks_as_list(input, joiner, prefix \\ "") do
    input = input |> Map.keys |> filter_keys(prefix)
    (input |> Enum.map(fn {k} -> k |> parse_key(joiner, prefix) end)) == (0..Enum.count(input) - 1 |> Enum.to_list)
  end
end
