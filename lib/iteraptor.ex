defmodule Iteraptor do
  @moduledoc """
  `Iteraptor` makes complicated nested structures (currently `map`s and `list`s)
    iteration easier.
  """

  @joiner "."

  @doc """
    Build a flatmap out of nested structure, concatenating the names of keys.

        %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
        %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}

    Lists are handled gracefully, index is used as a key in resulting map.

    **Parameters**

    - input: nested map/list/keyword to be flattened.
    - joiner: the character to be used to join keys while flattening,
    _optional_, default value is `"."`;
    e.g. `%{a: {b: 42}}` will be flattened to `%{"a.b" => 42}`.

    **Examples**

        iex> [:a, 42] |> Iteraptor.to_flatmap
        %{"0": :a, "1": 42}

        iex> %{a: 42} |> Iteraptor.to_flatmap
        %{a: 42}

        iex> %{a: 42, b: 42} |> Iteraptor.to_flatmap
        %{a: 42, b: 42}

        iex> %{a: %{b: 42}, d: 42} |> Iteraptor.to_flatmap
        %{"a.b" => 42, d: 42}

        iex> %{a: [:b, 42], d: 42} |> Iteraptor.to_flatmap
        %{"a.0" => :b, "a.1" => 42, d: 42}

        iex> %{a: %{b: [:c, 42]}, d: 42} |> Iteraptor.to_flatmap
        %{"a.b.0" => :c, "a.b.1" => 42, d: 42}

        iex> %{a: %{b: 42}} |> Iteraptor.to_flatmap
        %{"a.b" => 42}

        iex> %{a: %{b: %{c: 42}}} |> Iteraptor.to_flatmap
        %{"a.b.c" => 42}

        iex> %{a: %{b: %{c: 42}}, d: 42} |> Iteraptor.to_flatmap
        %{"a.b.c" => 42, d: 42}

        iex> [a: [b: [c: 42]], d: 42] |> Iteraptor.to_flatmap
        %{"a.b.c" => 42, d: 42}

        iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
        %{"a.b.c" => 42, "a.b.d.0" => nil, "a.b.d.1" => 42, "a.e.0" => :f, "a.e.1" => 42}
  """

  def to_flatmap(input, joiner \\ @joiner) when is_map(input) or is_list(input) do
    process(input, joiner)
  end

  @doc """
    Build a nested structure out of a flatmap given, decomposing the names of keys
    and handling lists carefully.

        %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42} |> Iteraptor.from_flatmap
        %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}

    **Parameters**

    - input: flat map to be “expanded” to nested maps/lists.
    - joiner: the character to be used to “un-join” keys while flattening,
    _optional_, default value is `"."`;
    e.g. `%{"a.b" => 42}` will be unveiled to `%{a: {b: 42}}`.

    **Examples**

        iex> %{"a.b.c": 42} |> Iteraptor.from_flatmap
        %{a: %{b: %{c: 42}}}

        iex> %{"a.b.c": 42, "a.b.d": 42} |> Iteraptor.from_flatmap
        %{a: %{b: %{c: 42, d: 42}}}

        iex> %{"a.b.c": 42, "a.b.d": 42, "a.e": 42} |> Iteraptor.from_flatmap
        %{a: %{b: %{c: 42, d: 42}, e: 42}}

        iex> %{"0": 42, "1": 42} |> Iteraptor.from_flatmap
        [42, 42]

        iex> %{"1": :a1, "0": :a0, "2": :a2, "3": :a3, "4": :a4, "5": :a5,
        ...>   "6": :a6, "7": :a7, "8": :a8, "9": :a9, "10": :a10, "11": :a11}
        ...> |> Iteraptor.from_flatmap
        [:a0, :a1, :a2, :a3, :a4, :a5, :a6, :a7, :a8, :a9, :a10, :a11]

        iex> %{"0.a": 42, "0.b": 42} |> Iteraptor.from_flatmap
        [%{a: 42, b: 42}]

        iex> %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
        ...> |> Iteraptor.from_flatmap
        %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}
  """
  def from_flatmap(input, joiner \\ @joiner) when is_map(input) do
    unprocess(input, joiner)
  end

  @doc """
    Iterates the given nested structure, calling the callback provided on each
    value. The key returned is a concatenated names of all the parent keys
    (and/or indices in a case of an array.)

    The return value is the result of call to `to_flatmap`.

    **Parameters**

    - input:  nested map/list/keyword to be walked through.
    - joiner: the character to be used to join keys while flattening,
    is returned to the callback as iterated key name;
    _optional_, default value is `"."`;
    - fun:    callback to be called on each _value_;
    e.g. on `%{a: {b: 42}}` will be called once, with tuple `{"a.b", 42}`.

    **Examples**

        iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(fn {k, v} -> IO.inspect({k, v}) end)
        %{"a.b.c" => 42}
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
    if Keyword.keyword?(input) do
      input |> Enum.into(%{}) |> process(joiner, prefix, acc, fun)
    else
      input
        |> Enum.with_index
        |> Enum.map(fn({k, v}) -> {v, k} end)
        |> Enum.into(%{})
        |> process(joiner, prefix, acc, fun)
    end
  end

  ##############################################################################

  defp unprocess(input, joiner, fun \\ nil)

  ### -----------------------------------------------------------------------###

  defp unprocess(input, joiner, fun) when is_map(input) do
    input
      |> Enum.reduce(%{}, fn({key, value}, acc) ->
        put_or_update(acc, joiner, key, value, fun)
      end)
      |> imply_lists(joiner)
  end

  ##############################################################################

  defp join(l, r \\ "", joiner \\ @joiner)

  defp join(l, "", joiner) do
    s = to_string l
    if s |> String.contains?(joiner) do
      s
    else
      String.to_atom s
    end
  end

  defp join("", r, joiner) do
    join(r, "", joiner)
  end

  defp join(l, r, joiner) do
    to_string to_string(l) <> joiner <> to_string(r)
  end

  ##############################################################################

  @lint [{Credo.Check.Refactor.Nesting, false}, {Credo.Check.Refactor.ABCSize, false}]
  defp put_or_update(input, joiner, prefix, value, fun, path \\ "") when is_map(input) do
    case prefix |> to_string |> String.split(joiner, parts: 2) do
      [key, rest] ->
        {_, target} = input |> Map.get_and_update(join(key), fn current ->
          old = case current do
            nil -> %{}
            _   -> current
          end
          {current, old |> put_or_update(joiner, rest, value, fun, join(path, key, joiner))}
        end)
        target
      [key] ->
        unless is_nil(fun), do: fun.({path, value})
        cond do
          is_map(input) ->  input |> Map.put(join(key), value)
          is_list(input) ->  input ++ [value]
          true -> input # FIXME raise ??
        end
    end
  end

  ##############################################################################

  defp parse_key(key, joiner, prefix) do
    k = key
        |> to_string
        |> String.split(joiner)
        |> Enum.at((prefix |> String.split(joiner) |> Enum.count) - 1)
    try do
      k |> String.to_integer
    rescue
      ArgumentError -> k
    end
  end

  defp filter_keys(input, prefix) do
    case prefix do
      "" -> input
      _  -> input |> Enum.filter(fn e -> e |> to_string |> String.starts_with?(to_string(prefix)) end)
    end
  end

  defp quacks_as_list(input, joiner, prefix \\ "") do
    input = input |> Map.keys |> filter_keys(prefix)
    (input
      |> Enum.map(fn k ->
        k |> parse_key(joiner, prefix)
      end)
      |> Enum.sort) == (0..Enum.count(input) - 1 |> Enum.to_list)
  end

  defp imply_lists(input, joiner) when is_map(input) do
    if quacks_as_list(input, joiner) do
      sorted = input
        |> Enum.sort(fn ({k1, _}, {k2, _}) ->
             String.to_integer(to_string(k1)) < String.to_integer(to_string(k2))
           end)
      for {_, v} <- sorted do
        if is_map(v), do: imply_lists(v, joiner), else: v
      end
    else
      Enum.into(for {k, v} <- input do
        {k, (if is_map(v), do: imply_lists(v, joiner), else: v)}
      end, %{})
    end
  end
end
