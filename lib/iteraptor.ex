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

  import Iteraptor.Updater

  @struct_joiner "%"

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
      %{0 => :a, 1 => 42}

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
    # process(input, :unknown, {into(opts), nil, nil}, opts)
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
    input
    |> try_to_list()
  end

  @doc """
  Iterates the given nested structure, calling the callback provided on each
  value. The key returned is a concatenated names of all the parent keys
  (and/or indices in a case of an array.)

  The return value is the result of call to `to_flatmap`.

  ## Parameters

  - `input`:  nested map/list/keyword to be walked through.
  - `fun`:    callback to be called on each _value_;
  e.g. on `%{a: {b: 42}}` will be called once, with tuple `{"a.b", 42}`;
  - `opts`: the options to be passed to the iteration
    - `joiner`: the character to be used to join keys while flattening,
      is returned to the callback as iterated key name;
      _optional_, default value is `"."`;

  ## Examples

      iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(fn {k, v} -> IO.inspect({k, v}) end)
      {"a.b.c", 42}
      %{a: %{b: %{c: 42}}}

      iex> %{a: %{b: %{c: 42}}}
      ...> |> Iteraptor.each(fn {k, v} -> IO.inspect({k, v}) end, full_parent: :tuple)
      {{:a, :b, :c}, 42}
      %{a: %{b: %{c: 42}}}
  """
  def each(input, fun, opts \\ []) do
    map(input, fun, opts)
    input
  end

  def map(input, fun, opts \\ []) do
    unless is_function(fun, 1), do: raise "Function or arity fun/1 is required"
    traverse(input, fun, opts)
  end

  ##############################################################################

  defp traverse(input, fun, opts, key \\ [])
  defp traverse(input, fun, opts, key) when is_list(input) or is_map(input) do
    {_type, into} = type(input)

    input
    |> Enum.with_index()
    |> Enum.map(fn {kv, idx} ->
         {k, v} =
           case kv do
             {k, v} -> {k, v}
             v -> {idx, v}
           end

         deep = key ++ [k]

         value =
           case {opts[:yield], is_map(v), is_list(v)} do
             {_, false, false} -> fun.({deep, v})
             {:all, _, _} -> fun.({deep, v})
             {:lists, _, true} -> fun.({deep, v})
             {:maps, true, _} -> fun.({deep, v})
             _ -> {deep, v}
           end
         case value do
           ^v -> {k, traverse(v, fun, opts, deep)}
           {^deep, _} -> {k, traverse(v, fun, opts, deep)}
           {^k, _} -> {k, traverse(v, fun, opts, deep)}
           {k, v} -> {k, traverse(v, fun, opts, deep)}
           v -> {k, traverse(v, fun, opts, deep)}
         end
       end)
    |> Enum.into(into)
    |> squeeze()
    |> try_to_list()
  end
  defp traverse(input, _fun, _opts, _key), do: input

  # defp process(input, :struct, {acc, key, fun}, opts) do
  #   struct_name = input.__struct__ |> inspect |> String.replace(".", struct_joiner(opts))
  #   input
  #     |> Map.keys
  #     |> Enum.reject(& &1 == :__struct__)
  #     |> Enum.map(fn e ->
  #          {"#{struct_name}%#{e}", get_in(input, [Access.key!(e)])}
  #        end)
  #     |> Enum.into(into(opts))
  #     |> process(Map, {acc, key, fun}, opts)
  # end

  ##############################################################################

  ##############################################################################

  # defp is_struct(input) when is_map(input) do
  #   input |> Enum.reduce(nil, fn {k, _}, acc ->
  #     case k |> to_string |> String.split(~r{#{@struct_joiner}(?=[^#{@struct_joiner}]*$)}) do
  #       [^acc, _] -> acc
  #       [struct_name, _] -> if acc == nil, do: struct_name, else: false
  #       _ -> false
  #     end
  #   end)
  # end
  # defp is_struct(_), do: false

end
