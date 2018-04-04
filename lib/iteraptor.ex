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

  @into %{}
  @joiner "."
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
    process(input, :unknown, {into(opts), nil, nil}, opts)
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
    finalize_opts = [yield_all: true, collapse_lists: true, full_parent: true]

    input
    |> unprocess(fun, opts)
    |> IO.inspect(label: "⚐")
    # |> fix(opts)
    |> map(fn {k, v} -> {k, maybe_make_list(v, [])} end, finalize_opts)
    |> maybe_make_list(opts)
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
    unless is_function(fun, 1), do: raise "Function or arity fun/1 is required"

    process(input, :unknown, {nil, nil, fun}, opts)
    input
  end

  def map(input, fun, opts \\ []) do
    unless is_function(fun, 1), do: raise "Function or arity fun/1 is required"

    result = process(input, :unknown, {nil, nil, fun}, opts)
    if opts[:full_parent], do: result, else: from_flatmap(result)
    # |> fix(opts)
  end

  ##############################################################################

  defp process(input, type, acc_key_fun, opts)

  ### -----------------------------------------------------------------------###

  defp process(_, _, _, opts) when not is_list(opts),
    do: raise ArgumentError, message: "Options must be a keyword list: #{inspect opts}"

  defp process(_, :invalid, {_, key, _}, _),
    do: raise ArgumentError, message: "Unsupported data type found at prefix: #{inspect key}"

  defp process(input, :unknown, {acc, key, fun}, opts) do
    {type, _} = type(input)
    key = safe_join(key, nil, opts)
    process(input, type, {acc, key, fun}, opts)
  end

  defp process(input, type, {acc, key, fun}, opts) when type in [Map, Keyword] do
    input
    |> Enum.reduce(acc, fn({k, v}, memo) ->
        key = safe_join(key, k, opts)
        {_, value} =
          case {fun, opts[:yield_all] || (!is_map(v) && !is_list(v))} do
            {f, true} when is_function(f, 1) ->
              original_key =
                if opts[:full_parent] == :tuple, do: List.to_tuple(key), else: key
              case f.({original_key, v}) do
                {^original_key, value} -> {key, value}
                {key, value} -> {key, value}
                value -> {key, value}
              end
            _ -> {key, v}
          end

        if is_map(value) or is_list(value) do
          memo =
            if opts[:full_parent] do
              with {_, instance} <- type(input), do: safe_put_in(memo, key, instance)
            else
              memo
            end
          process(value, :unknown, {memo, key, fun}, opts)
        else
          safe_put_in(memo, key, value)
        end
    end)
  end

  defp process(input, List, {acc, key, fun}, opts) do
    if opts[:collapse_lists] do
      value =
        input
        |> Enum.map(fn v ->
             case type(v) do
              {:invalid, _} ->
                safe_put_in(acc, key, v)
                |> IO.inspect(label: "⚑0")
              {type, instance} ->
                acc = safe_put_in(acc, key, instance)
                v
                |> IO.inspect(label: "⚑1")
                |> process(type, {acc, key, fun}, opts)
                |> IO.inspect(label: "⚑2")
             end
           end)
        |> maybe_make_list(opts)
      safe_put_in(acc, key, value)
    else
      input
      |> Enum.with_index()
      |> Enum.map(fn {k, idx} -> {idx, k} end)
      |> Enum.into(into(opts))
      |> process(Map, {acc, key, fun}, opts)
    end
  end

  defp process(input, :struct, {acc, key, fun}, opts) do
    struct_name = input.__struct__ |> inspect |> String.replace(".", struct_joiner(opts))
    input
      |> Map.keys
      |> Enum.reject(& &1 == :__struct__)
      |> Enum.map(fn e ->
           {"#{struct_name}%#{e}", get_in(input, [Access.key!(e)])}
         end)
      |> Enum.into(into(opts))
      |> process(Map, {acc, key, fun}, opts)
  end

  ##############################################################################

  defp unprocess(input, fun, opts)

  ### -----------------------------------------------------------------------###

  defp unprocess(input, fun, opts) when is_map(input) or is_list(input) do
    input
    |> shave_off(fun, opts)
    |> squeeze(opts)
    # |> fix(opts)
  end

  ##############################################################################

  defp safe_join(parent, key, opts) when not is_list(key) do
    case {parent, to_string(key), opts[:full_parent] || :joined} do
      {p, "", :joined} when is_nil(p) or p == [] or p == "" -> ""
      {p, "", _} when is_nil(p) or p == [] or p == "" -> []
      {_, "", _} -> parent
      {p, _, :joined} when is_nil(p) or p == [] or p == "" -> key
      {p, _, _} when is_nil(p) or p == [] or p == "" -> [key]
      # {_, _, :joined} -> join(parent, key, joiner(opts) )
      {_, _, _} -> parent ++ [key]
    end
  end

  ##############################################################################

  def safe_put_in(memo, key, v) when is_list(key), do: put_in(memo, key, v)
  def safe_put_in(memo, key, v) when is_atom(key), do: put_in(memo, [key], v)
  def safe_put_in(memo, key, v) when is_list(memo), do: memo ++ [{key, v}]
  def safe_put_in(memo, key, v) when is_map(memo), do: Map.put(memo, key, v)

  defp key_splitter(value, opts)
  defp key_splitter({[head | tail], value}, _opts), do: {head, tail, value}
  defp key_splitter({key, value}, _opts) when is_tuple(key),
    do: with [head | tail] <- Tuple.to_list(key), do: {head, tail, value}
  defp key_splitter({key, value}, opts) when is_binary(key) do
    [head | tail] = String.split(key, joiner(opts), parts: 2)
    with {parsed_integer, ""} <- Integer.parse(head) do
      {parsed_integer, tail, value}
    else
      _ -> {String.to_existing_atom(head), tail, value}
    end
  end
  defp key_splitter({key, value}, opts) when is_atom(key) do
    if key |> Atom.to_string() |> String.contains?(joiner(opts)) do
      key_splitter({Atom.to_string(key), value}, opts)
    else
      {key, [], value}
    end
  end
  defp key_splitter({key, value}, _opts), do: {key, [], value}



  def squeeze1(input, opts) do
    instance = into(opts)

    input
    |> Enum.reduce(instance, fn kv, acc ->
        IO.inspect(kv, label: "▶")
        {:ok, {deep_key, value}} = dig([kv])
        {key, acc} =
          Enum.reduce(deep_key, {[], acc}, fn k, {key, acc} ->
            key = key ++ [k]
            acc =
              case get_in(acc, key) do
              nil -> put_in(acc, key, instance)
              _ -> acc
              end
            {key, acc}
          end)
        put_in(acc, key, value)
      end)
  end

  defp maybe_make_list(input, opts) when is_list(input) or is_map(input) do
    is_squeezable_map =
      is_list(input) &&

      input
      |> Enum.flat_map(fn
           map when is_map(map) -> Map.keys(map)
           _ -> []
         end)
      |> Enum.uniq()
      |> Enum.count() == 1

    cond do
      is_squeezable_map ->
        Enum.map(input, fn
          map when is_map(map) -> map |> Map.values() |> hd()
          _ -> []
        end)

      quacks_as_list(input, joiner(opts)) ->
        input
        |> Enum.map(& key_splitter(&1, opts))
        |> Enum.chunk_by(fn {key, _, _} -> key end)
        |> Enum.sort_by(fn [{key, _, _} | _] ->
            key |> to_string() |> String.to_integer()
          end)
        |> Enum.map(fn
            [{_, [], value}] -> value
            list -> Enum.map(list, fn {_, key, value} -> {key, value} end)
        end)

      true -> input
    end
  end
  defp maybe_make_list(input, _), do: input

  defp shave_off(input, fun, opts) when is_map(input) or is_list(input) do
    # level =
    #  if quacks_as_list(input, joiner(opts)),
    #    do: make_list(input, opts), else: input
    # {_, acc} = type(input)
    # |> Enum.into(acc)

    input
    |> Enum.with_index()
    |> Enum.map(fn
      {{k, v}, _} ->
        {k, rest, v} = key_splitter({k, v}, opts)
        unless is_nil(fun), do: fun.({k, v}) # FIXME
        v =
          case rest do
            [] -> v
            "" -> v
            [key] -> %{key => v}
          end
        {k, shave_off(v, fun, opts)}
      {v, idx} ->
        unless is_nil(fun), do: fun.({idx, v}) # FIXME
        shave_off(v, fun, opts)
    end)
  end
  defp shave_off(input, _fun, _opts), do: input

  ##############################################################################

  defp into(opts), do: opts[:into] || @into
  defp joiner(opts), do: opts[:joiner] || @joiner

  defp struct_joiner(opts), do: opts[:struct_joiner] || @struct_joiner

  defp parse_key(key, joiner, prefix \\ "") do
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
    IO.inspect(input, label: "★★★")
    input =
      input
      |> Enum.map(fn
           {k, _v} -> to_string(k)
           v -> v
         end)
      |> filter_keys(prefix)
      |> Enum.map(& parse_key(&1, joiner, prefix))
      |> Enum.uniq()
      |> Enum.sort()
    input == (0..Enum.count(input) - 1 |> Enum.to_list)
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
  defp is_struct(_), do: false

  defp imply_lists(input, joiner) when is_map(input) or is_list(input) do
    if quacks_as_list(input, joiner) do
      sorted =
        Enum.sort(input, fn ({k1, _}, {k2, _}) ->
          parse_key(k1, joiner) < parse_key(k2, joiner)
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
