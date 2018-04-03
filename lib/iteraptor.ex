defmodule Iteraptor do
  @moduledoc """
  `Iteraptor` makes complicated nested structures (currently `map`s, `list`s
    and somehow `Keyword`s) iteration easier.

  ## Usage

  ### `to_flatmap`:

      iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
      %{"a.b.c" => 42, "a.b.d.0" => nil, "a.b.d.1" => 42, "a.e.0" => :f, "a.e.1" => 42}

  ### `from_flatmap`:

      iex> %{"a.b.c" => 42, "a.b.d.0" => nil, "a.b.d.1" => 42, "a.e.0" => :f, "a.e.1" => 42}
      ...> |> Iteraptor.from_flatmap
      %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}

  ### `each`:

      %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}
        |> Iteraptor.each(fn({k, v}) ->
          Logger.debug(k <> " ⇒ " <> inspect(v))
        end)

  Returning:

      a.b.c ⇒ 42
      a.b.d.0 ⇒ nil
      a.b.d.1 ⇒ 42
      a.e.0 ⇒ :f
      a.e.1 ⇒ 42

  """

  @joiner "."
  @struct_joiner "%"

  defguard is_key_value(type) when type in ~w|map keyword|a

  @doc """
  Build a flatmap out of nested structure, concatenating the names of keys.

      %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
      %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}

  Lists are handled gracefully, index is used as a key in resulting map.

  ## Parameters

  - `input`: nested map/list/keyword/struct to be flattened.
  - `joiner`: the character to be used to join keys while flattening,
  _optional_, default value is `"."`;
  e.g. `%{a: {b: 42}}` will be flattened to `%{"a.b" => 42}`.

  ## Examples

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

      iex> [a: [[:b], 42], d: 42] |> Iteraptor.to_flatmap
      %{"a.0.0" => :b, "a.1" => 42, d: 42}

      iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
      %{"a.b.c" => 42, "a.b.d.0" => nil, "a.b.d.1" => 42, "a.e.0" => :f, "a.e.1" => 42}

      iex> %Struct1{field1: %Struct2{field2: [%{a: 42}, :b]}} |> Iteraptor.to_flatmap
      %{"Struct1%field1.Struct2%field2.0.a" => 42, "Struct1%field1.Struct2%field2.1" => :b}
  """

  def to_flatmap(input, opts \\ []) when is_map(input) or is_list(input) do
    process(input, :unknown, {%{}, "", nil}, opts)
  end

  @doc """
  Build a nested structure out of a flatmap given, decomposing the names of keys
  and handling lists carefully.

      %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42} |> Iteraptor.from_flatmap
      %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}

  ## Parameters

  - `input`: flat map to be “expanded” to nested maps/lists.
  - `joiner`: the character to be used to “un-join” keys while flattening,
  _optional_, default value is `"."`;
  e.g. `%{"a.b" => 42}` will be unveiled to `%{a: {b: 42}}`.

  ## Examples

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

      iex> %{"a.0.0" => :b, "a.1" => 42, d: 42} |> Iteraptor.from_flatmap
      %{a: [[:b], 42], d: 42}

      iex> %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
      ...> |> Iteraptor.from_flatmap
      %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}

      iex> %{"Struct1%field1.Struct2%field2.0.a" => 42, "Struct1%field1.Struct2%field2.1" => :b}
      ...> |> Iteraptor.from_flatmap
      %Struct1{field1: %Struct2{field2: [%{a: 42}, :b]}}
  """
  def from_flatmap(input, fun \\ nil, opts \\ []) when is_map(input) do
    unprocess(input, fun, opts)
  end

  @doc """
  Iterates the given nested structure, calling the callback provided on each
  value. The key returned is a concatenated names of all the parent keys
  (and/or indices in a case of an array.)

  The return value is the result of call to `to_flatmap`.

  ## Parameters

  - `input`:  nested map/list/keyword to be walked through.
  - `joiner`: the character to be used to join keys while flattening,
  is returned to the callback as iterated key name;
  _optional_, default value is `"."`;
  - `fun`:    callback to be called on each _value_;
  e.g. on `%{a: {b: 42}}` will be called once, with tuple `{"a.b", 42}`.

  ## Examples

      iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
      %{"a.b.c" => 42}
  """
  def each(input, fun, opts \\ []) do
    unless is_function(fun, 1), do: raise "Function or arity fun/1 is required"
    process(input, :unknown, {nil, nil, fun}, opts)
  end

  ##############################################################################

  defp process(input, type, acc_key_fun, opts)

  ### -----------------------------------------------------------------------###

  defp process(_, _, _, opts) when not is_list(opts),
    do: raise ArgumentError, message: "Options must be a keyword list: #{opts.inspect}"

  defp process(_, :invalid, {_, key, _}, _),
    do: raise ArgumentError, message: "Unsupported data type found at prefix: #{key}"

  defp process(input, :unknown, {acc, key, fun}, opts) do
    {type, instance} = type(input, acc)
    key = safe_join(key, nil, opts)
    process(input, type, {instance, key, fun}, opts)
  end

  defp process(input, type, {acc, key, fun}, opts) when is_key_value(type) do
    input
    |> Enum.reduce(acc, fn({k, v}, memo) ->
        key = safe_join(key, k, opts) # FIXME JOIN
        if is_map(v) or is_list(v) do
          with {_, instance} <- type(input),
               memo <- safe_put_in(memo, key, instance),
            do: process(v, :unknown, {memo, key, fun}, opts)
        else
          unless is_nil(fun),
            do: fun.({(if opts[:full_parent] == :tuple, do: List.to_tuple(key), else: key), v})
          safe_put_in(memo, key, v)
        end
    end)
  end

  defp process(input, :list, {acc, key, fun}, opts) do
    input
    |> Enum.with_index
    |> Enum.map(fn({k, v}) -> {v, k} end)
    |> Enum.into(%{})
    |> process(:map, {acc, key, fun}, opts)
  end

  defp process(input, :struct, {acc, key, fun}, opts) do
    struct_name = input.__struct__ |> inspect |> String.replace(".", struct_joiner(opts))
    input
      |> Map.keys
      |> Enum.filter(fn e -> e != :__struct__ end)
      |> Enum.map(fn e ->
           {"#{struct_name}%#{e}", get_in(input, [Access.key!(e)])}
         end)
      |> Enum.into(%{})
      |> process(:map, {acc, key, fun}, opts)
  end

  ##############################################################################

  defp unprocess(input, fun, opts)

  ### -----------------------------------------------------------------------###

  defp unprocess(input, fun, opts) when is_map(input) do
    input
    |> Enum.reduce(%{}, fn({key, value}, acc) ->
      put_or_update(acc, key, value, fun, opts)
    end)
    |> imply_lists(joiner(opts))
  end

  ##############################################################################

  defp type(input, default \\ nil) do
    {type, instance} =
      case Enumerable.impl_for(input) do
        Enumerable.List ->
          {(if Keyword.keyword?(input), do: :keyword, else: :list), []}
        Enumerable.Map ->
          {:map, %{}}
        _ ->
        # FIXME struct instantiation is potentially dangerous
          if is_map(input), do: {:struct, struct(input.__struct__)}, else: {:invalid, nil}
      end
    {type, default || instance}
  end

  defp safe_join(parent, key, opts) when not is_list(key) do
    case {parent, to_string(key), opts[:full_parent] || :joined} do
      {p, "", :joined} when is_nil(p) or p == [] or p == "" -> ""
      {p, "", _} when is_nil(p) or p == [] or p == "" -> []
      {_, "", _} -> parent
      {p, _, :joined} when is_nil(p) or p == [] or p == "" -> to_string(key)
      {p, _, _} when is_nil(p) or p == [] or p == "" -> [key]
      {_, _, :joined} -> join(parent, key, joiner(opts) )
      {_, _, _} -> parent ++ [key]
    end
  end

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

  def safe_put_in(memo, key, v) when is_list(key), do: put_in(memo, key, v)
  def safe_put_in(memo, key, v) when is_atom(key), do: put_in(memo, [key], v)
  def safe_put_in(memo, key, v) when is_list(memo) and is_binary(key), do: memo ++ [{key, v}]
  def safe_put_in(memo, key, v) when is_map(memo), do: Map.put(memo, key, v)

  defp put_or_update(input, key, value, fun, opts, path \\ "") when is_map(input) do
    case key |> to_string |> String.split(joiner(opts), parts: 2) do
      [key, rest] ->
        {_, target} = input |> Map.get_and_update(join(key), fn current ->
          old = case current do
            nil -> %{}
            _   -> current
          end
          {current, old |> put_or_update(rest, value, fun, opts, join(path, key, joiner(opts)))}
        end)
        target
      [key] ->
        unless is_nil(fun), do: fun.({path, value})
        Map.put(input, join(key), value)
    end
  end

  ##############################################################################

  defp joiner(opts), do: opts[:joiner] || @joiner

  defp struct_joiner(opts), do: opts[:struct_joiner] || @struct_joiner

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

  defp is_struct(input) when is_map(input) do
    input |> Enum.reduce(nil, fn {k, _}, acc ->
      case k |> to_string |> String.split(~r{#{@struct_joiner}(?=[^#{@struct_joiner}]*$)}) do
        [^acc, _] -> acc
        [struct_name, _] -> if acc == nil, do: struct_name, else: false
        _ -> false
      end
    end)
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
      target = case is_struct(input) do
                 false -> %{}
                 name  -> struct(Module.concat(Elixir, name |> to_string |> String.replace(@struct_joiner, ".")))
               end
      input |> Enum.reduce(target, fn {k, v}, acc ->
        key = join(~r{.*#{@struct_joiner}} |> Regex.replace(to_string(k), ""))
        acc |> Map.put(join(key), (if is_map(v), do: imply_lists(v, joiner), else: v))
      end)
    end
  end
end
