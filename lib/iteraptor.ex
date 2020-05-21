defmodule Iteraptor do
  @moduledoc """
  `Iteraptor` makes complicated nested structures (currently `Map`s, `List`s
    and `Keyword`s) iteration easier.

  ## Usage

  #### Iterating, Mapping, Reducing

  * [`Iteraptor.each/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#each/3)
    to iterate a deeply nested map/list/keyword;
  * [`Iteraptor.map/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#map/3)
    to map a deeply nested map/list/keyword;
  * [`Iteraptor.reduce/4`](https://hexdocs.pm/iteraptor/Iteraptor.html#reduce/4)
    to reduce a deeply nested map/list/keyword;
  * [`Iteraptor.map_reduce/4`](https://hexdocs.pm/iteraptor/Iteraptor.html#map_reduce/4)
    to map and reduce a deeply nested map/list/keyword;

  #### Flattening

  * [`Iteraptor.to_flatmap/2`](https://hexdocs.pm/iteraptor/Iteraptor.html#to_flatmap/2)
    to flatten a deeply nested map/list/keyword into
    flatten map with concatenated keys;
  * [`Iteraptor.from_flatmap/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#from_flatmap/3)
    to “unveil”/“unflatten” the previously flattened map into nested structure;

  #### Filtering

  * [`Iteraptor.filter/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#filter/3)
    to filter the structure according to the value returned from each iteration
    (`true` to leave the element, `false` to discard.)
  """

  import Iteraptor.Utils

  @doc """
  Build a flatmap out of nested structure, concatenating the names of keys.

      %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
      %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}

  Lists are handled gracefully, index is used as a key in resulting map.

  ## Parameters

  - `input`: nested map/list/keyword/struct to be flattened,  
  - `opts`: the additional options to be passed through:  
    — `delimiter` (_default:_ `"."`,) might be passed explicitly or
    configured with `:iteraptor, :delimiter` application setting.

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

      iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}
      ...> |> Iteraptor.to_flatmap(delimiter: "_")
      %{"a_b_c" => 42, "a_b_d_0" => nil, "a_b_d_1" => 42, "a_e_0" => :f, "a_e_1" => 42}
  """

  @spec to_flatmap(%{} | [...], Keyword.t()) :: %{}

  def to_flatmap(input, opts \\ []) when is_map(input) or is_list(input) do
    reducer = fn {k, v}, acc ->
      key =
        case k do
          [key] -> key
          _ -> Enum.join(k, delimiter(opts))
        end

      Map.put(acc, key, v)
    end

    with {_, flattened} <- reduce(input, %{}, reducer, opts), do: flattened
  end

  @doc """
  Build a nested structure out of a flatmap given, decomposing the names of keys
  and handling lists carefully.

      %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
      |> Iteraptor.from_flatmap
      #⇒ %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}

  ## Parameters

  - `input`: flat map to be “expanded” to nested maps/lists,  
  - `transformer`: the transformer function to be called on all the elements,  
  - `opts`: additional options to be passed through.

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

      iex> %{"0.a": 42, "0.b": 42} |> Iteraptor.from_flatmap(&IO.inspect/1)
      {[0, :a], 42}
      {[0, :b], 42}
      [%{a: 42, b: 42}]
  """
  @spec from_flatmap(%{}, ({any(), any()} -> any()) | nil, Keyword.t()) ::
          %{} | [...] | Keyword.t()

  def from_flatmap(input, transformer \\ nil, opts \\ []) when is_map(input) do
    reducer = fn {k, v}, acc ->
      key =
        case k |> Enum.join(delimiter(opts)) |> String.split(delimiter(opts)) do
          [k] -> [smart_convert(k)]
          list -> Enum.map(list, &smart_convert/1)
        end

      value =
        if is_nil(transformer) do
          v
        else
          case transformer.({key, v}) do
            {^key, any} -> any
            any -> any
          end
        end

      deep_put_in(acc, {key, value}, opts)
    end

    input
    |> reduce(%{}, reducer, opts)
    |> squeeze()
  end

  @doc """
  Iterates the given nested structure, calling the callback provided on each
    value. The key returned is an array of all the parent keys (and/or indices
    in a case of an array.)

  The return value is `self`.

  ## Parameters

  - `input`: nested map/list/keyword to be walked through.
  - `fun`: callback to be called on each **`{key, value}`** pair, where `key`
    is an array or deeply nested keys;
  e.g. on `%{a: {b: 42}}` will be called once, with tuple `{[:a, :b], 42}`;
  - `opts`: the options to be passed to the iteration
    - `yield`: `[:all | :maps | :keywords | nil]` what to yield; _default:_ `nil`
    for yielding _values only_
    - `structs`: `[:values | :keep | nil]` how to handle structs;  _default:_ `nil`
    for treating them as `map`s. When `:values`, the nested structs
    are considered leaves and returned to the iterator instead of being iterated
    through; when `:keep` it returns a struct back after iteration

  ## Examples

      iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(&IO.inspect/1)
      {[:a, :b, :c], 42}
      %{a: %{b: %{c: 42}}}

      iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(&IO.inspect/1, yield: :all)
      {[:a], %{b: %{c: 42}}}
      {[:a, :b], %{c: 42}}
      {[:a, :b, :c], 42}
      %{a: %{b: %{c: 42}}}
  """

  @spec each(%{} | Keyword.t() | [...] | Access.t(), ({any(), any()} -> any()), Keyword.t()) ::
          %{} | Keyword.t() | [...] | Access.t()

  def each(input, fun, opts \\ []) do
    map(input, fun, opts)
    input
  end

  @doc """
  Maps the given nested structure, calling the callback provided on each value.
    The key returned is a concatenated names of all the parent keys
  (and/or indices in a case of an array.)

  The return value is the result of subsequent calls to the transformer given.

  ## Parameters

  - `input`: nested map/list/keyword to be mapped.
  - `fun`: callback to be called on each **`{key, value}`** pair, where `key`
    is an array or deeply nested keys;
  e.g. on `%{a: {b: 42}}` will be called once, with tuple `{[:a, :b], 42}`;
  - `opts`: the options to be passed to the iteration
    - `yield`: `[:all | :maps | :keywords |` what to yield; _default:_ `nil`
    for yielding _values only_.

  ## Examples

      iex> %{a: %{b: %{c: 42}}} |> Iteraptor.map(fn {_, v} -> v * 2 end)
      %{a: %{b: %{c: 84}}}

      iex> %{a: %{b: %{c: 42}}} |> Iteraptor.map(fn {k, _} -> Enum.join(k) end)
      %{a: %{b: %{c: "abc"}}}

      iex> %{a: %{b: %{c: 42}}}
      ...> |> Iteraptor.map(fn
      ...>      {[_], _} = self -> self
      ...>      {[_, _], _} -> "YAY"
      ...>    end, yield: :all)
      %{a: %{b: "YAY"}}
  """

  @spec map(%{} | Keyword.t() | [...] | Access.t(), ({any(), any()} -> any()), Keyword.t()) ::
          %{} | Keyword.t() | [...] | Access.t()

  def map(input, fun, opts \\ []) do
    unless is_function(fun, 1), do: raise("Function or arity fun/1 is required")

    {type, _, into} = type(input)
    {result, _} = traverse(input, fun, opts, {[], into})

    if opts[:structs] == :keep && is_map(result) and type != Map,
      do: struct(type, result),
      else: result
  end

  @doc """
  Iteration with reducing. The function of arity `2`, called back on each
    iteration with `{k, v}` pair _and_ an accumulator is accepted.

  The return value is the result of the last call to the passed reducer function.

  ## Parameters

  - `input`: nested map/list/keyword to be mapped.
  - `fun`: callback to be called on each **`{key, value}, acc`** pair,
    where `key` is an array or deeply nested keys, `value` is the value and
    `acc` is the accumulator;
  - `opts`: the options to be passed to the iteration
    - `yield`: `[:all | :maps | :keywords |` what to yield; _default:_ `nil`
    for yielding _values only_.

  ## Examples

      iex> %{a: %{b: %{c: 42}}}
      ...> |> Iteraptor.reduce([], fn {k, _}, acc ->
      ...>      [Enum.join(k, "_") | acc]
      ...>    end, yield: :all)
      ...> |> :lists.reverse()
      ["a", "a_b", "a_b_c"]
  """

  @spec reduce(
          %{} | Keyword.t() | [...] | Access.t(),
          %{} | Keyword.t() | [...] | Access.t(),
          ({any(), any()}, any() -> any()),
          Keyword.t()
        ) :: {%{} | Keyword.t() | [...] | Access.t(), any()}

  def reduce(input, acc \\ nil, fun, opts \\ []) do
    unless is_function(fun, 2), do: raise("Function or arity fun/2 is required")

    {type, _, into} = type(input)
    acc = if is_nil(acc), do: into, else: acc
    fun_wrapper = fn kv, acc -> {kv, fun.(kv, acc)} end
    {_, result} = traverse(input, fun_wrapper, opts, {[], acc})

    if opts[:structs] == :keep && is_map(result) and type != Map,
      do: struct(type, result),
      else: result
  end

  @doc """
  Iteration with mapping and reducing. The function of arity `2`, called back on each
    iteration with `{k, v}` pair _and_ an accumulator is accepted.

  The return value is the tuple, consisting of mapped input _and_ the
    accumulator from the last call to the passed map-reducer.

  ## Parameters

  - `input`: nested map/list/keyword to be mapped.
  - `fun`: callback to be called on each **`{key, value}, acc`** pair,
    where `key` is an array or deeply nested keys, `value` is the value and
    `acc` is the accumulator;
  - `opts`: the options to be passed to the iteration
    - `yield`: `[:all | :maps | :keywords |` what to yield; _default:_ `nil`
    for yielding _values only_.

  ## Examples

      iex> %{a: %{b: %{c: 42}}}
      ...> |> Iteraptor.map_reduce([], fn
      ...>      {k, %{} = v}, acc -> {{k, v}, [Enum.join(k, ".") | acc]}
      ...>      {k, v}, acc -> {{k, v * 2}, [Enum.join(k, ".") <> "=" | acc]}
      ...>    end, yield: :all)
      {%{a: %{b: %{c: 84}}}, ["a.b.c=", "a.b", "a"]}
  """

  @spec map_reduce(
          %{} | Keyword.t() | [...] | Access.t(),
          %{} | Keyword.t() | [...] | Access.t(),
          ({any(), any()}, any() -> any()),
          Keyword.t()
        ) :: {%{} | Keyword.t() | [...] | Access.t(), any()}

  def map_reduce(input, acc \\ %{}, fun, opts \\ []) do
    unless is_function(fun, 2), do: raise("Function or arity fun/2 is required")

    {type, _, into} = type(input)
    acc = if is_nil(acc), do: into, else: acc
    {map_result, result} = traverse(input, fun, opts, {[], acc})

    result =
      if opts[:structs] == :keep && is_map(result) and type != Map,
        do: struct(type, result),
        else: result

    {map_result, result}
  end

  @doc """
  Filters the deeply nested term, optionally calling the function on
  filtered entries.

  The return value is the filtered term.

  ## Parameters

  - `input`: nested map/list/keyword to be filtered.
  - `fun`: callback to be called on each **`{key, value}`** to filter entries.
  - `opts`: the options to be passed to the iteration
    - `yield`: `[:all | :maps | :keywords |` what to yield; _default:_ `nil`
    for yielding _values only_.

  ## Examples

      iex> %{a: %{b: 42, e: %{f: 3.14, c: 42}, d: %{c: 42}}, c: 42, d: 3.14}
      ...> |> Iteraptor.filter(fn {key, _} -> :c in key end, yield: :none)
      %{a: %{e: %{c: 42}, d: %{c: 42}}, c: 42}
  """

  @spec filter(%{} | Keyword.t() | [...] | Access.t(), ({any(), any()} -> any()), Keyword.t()) ::
          {%{} | Keyword.t() | [...] | Access.t(), any()}

  def filter(input, fun, opts \\ []) do
    unless is_function(fun, 1), do: raise("Function or arity fun/1 is required")
    {type, _, acc} = type(input)

    fun_wrapper = fn {k, v}, acc ->
      if fun.({k, v}), do: {{k, v}, deep_put_in(acc, {k, v}, opts)}, else: {{k, v}, acc}
    end

    {_, result} = traverse(input, fun_wrapper, opts, {[], acc})

    if opts[:structs] == :keep && is_map(result) and type != Map,
      do: struct(type, result),
      else: result
  end

  @doc """
  Produces a term ready-to-use with JSON interchange. Stringifies all keys
  and converts keywords to maps.

  ## Examples

      iex> Iteraptor.jsonify([foo: [:zzz], bar: :baz], values: true)
      %{"foo" => ["zzz"], "bar" => "baz"}

      iex> Iteraptor.jsonify(%{foo: [1, [bar: 2], 3], bar: [baz: 42]})
      %{"foo" => [1, %{"bar" => 2}, 3], "bar" => %{"baz" => 42}}

      iex> Iteraptor.jsonify([foo: [bar: [baz: :zoo], boo: 42]], values: true)
      %{"foo" => %{"bar" => %{"baz" => "zoo"}, "boo" => 42}}

      iex> Iteraptor.jsonify([foo: [bar: [baz: :zoo], boo: 42]], keys: false)
      %{foo: %{bar: %{baz: :zoo}, boo: 42}}
  """
  @spec jsonify(Access.container() | any(), opts :: list()) :: %{required(binary()) => any()}
  def jsonify(input, opts \\ [])
  def jsonify([{_, _} | _] = input, opts), do: input |> Map.new() |> jsonify(opts)
  def jsonify(input, opts) when is_list(input), do: Enum.map(input, &jsonify(&1, opts))

  def jsonify(input, opts) when not (is_map(input) or is_list(input)),
    do: if(opts[:values] && is_atom(input), do: to_string(input), else: input)

  def jsonify(input, opts) do
    stringify_keys = Keyword.get(opts, :keys, true)

    Iteraptor.map(
      input,
      fn
        {k, [{_, _} | _] = kw} when is_list(k) ->
          {k |> List.last() |> do_stringify(stringify_keys), jsonify(kw, opts)}

        {k, v} when is_list(k) ->
          {k |> List.last() |> do_stringify(stringify_keys), jsonify(v, opts)}
      end,
      yield: :all
    )
  end

  @spec do_stringify(any(), boolean()) :: any() | binary()
  defp do_stringify(k, false), do: k
  defp do_stringify(k, _) when is_atom(k), do: Atom.to_string(k) # faster
  defp do_stringify(k, _), do: to_string(k)

  ##############################################################################

  @spec traverse_callback(({any(), any()} -> any()) | (any(), any() -> any()), {any(), any()}) ::
          {any(), any()}

  defp traverse_callback(fun, {value, acc}) do
    case fun do
      f when is_function(fun, 1) -> {f.(value), nil}
      f when is_function(fun, 2) -> f.(value, acc)
    end
  end

  defmacrop traverse_value({k, v}, fun, opts, {deep, acc}) do
    quote do
      {value, acc} = traverse(unquote(v), unquote(fun), unquote(opts), unquote({deep, acc}))
      {{unquote(k), value}, acc}
    end
  end

  @spec traverse(
          %{} | Keyword.t() | [...] | Access.t(),
          ({any(), any()} -> any()) | (any(), any() -> any()),
          Keyword.t(),
          {[any()], any()}
        ) :: {%{} | Keyword.t() | [...] | Access.t(), any()}

  defp traverse(input, fun, opts, key_acc)

  # credo:disable-for-lines:41
  defp traverse(input, fun, opts, {key, acc}) when is_list(input) or is_map(input) do
    {type, from, into} = type(input)

    s_as_v = opts[:structs] == :values

    if is_map(from) and type != Map and s_as_v do
      {input, acc}
    else
      {value, acc} =
        from
        |> Enum.with_index()
        |> Enum.map_reduce(acc, fn {kv, idx}, acc ->
          {k, v} =
            case kv do
              {k, v} -> {k, v}
              v -> {idx, v}
            end

          deep = key ++ [k]

          {value, acc} =
            case {opts[:yield], is_map(v) and not s_as_v, is_list(v)} do
              {_, false, false} -> traverse_callback(fun, {{deep, v}, acc})
              {:all, _, _} -> traverse_callback(fun, {{deep, v}, acc})
              {:lists, _, true} -> traverse_callback(fun, {{deep, v}, acc})
              {:maps, true, _} -> traverse_callback(fun, {{deep, v}, acc})
              _ -> {{deep, v}, acc}
            end

          case value do
            ^v -> traverse_value({k, v}, fun, opts, {deep, acc})
            {^deep, v} -> traverse_value({k, v}, fun, opts, {deep, acc})
            {^k, v} -> traverse_value({k, v}, fun, opts, {deep, acc})
            {k, v} -> traverse_value({k, v}, fun, opts, {deep, acc})
            v -> traverse_value({k, v}, fun, opts, {deep, acc})
          end
        end)

      result = Enum.into(value, into)

      result =
        if opts[:structs] == :keep && is_map(result) and type != Map,
          do: struct(type, result),
          else: result

      {squeeze(result, opts), acc}
    end
  end

  defp traverse(input, _fun, _opts, {_key, acc}), do: {input, acc}

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
