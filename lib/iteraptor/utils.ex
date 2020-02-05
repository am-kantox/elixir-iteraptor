defmodule Iteraptor.Utils do
  @moduledoc "Helper functions to update nested terms"

  defmodule Unsupported do
    @moduledoc """
    An exception to be thrown from banged methods of `Iteraptor`.

    Sooner or later we’ll support everything, that’s why meanwhile
      we raise `Unsupported` if something goes wrong.
    """

    defexception [:term, :function, :message]

    def exception(term: term, function: function) do
      message = "Unsupported term #{inspect(term)} in call to #{function}."
      %Iteraptor.Utils.Unsupported{term: term, function: function, message: message}
    end
  end

  @doc """
  Determines the type of the given term.

  ## Examples:

      iex> Iteraptor.Utils.type(%{foo: :bar})
      {Map, %{foo: :bar}, %{}}
      iex> Iteraptor.Utils.type([foo: :bar])
      {Keyword, [foo: :bar], []}
      iex> Iteraptor.Utils.type([{:foo, :bar}])
      {Keyword, [{:foo, :bar}], []}
      iex> Iteraptor.Utils.type(~w|foo bar|a)
      {List, [:foo, :bar], []}
      iex> Iteraptor.Utils.type(42)
      :error
  """
  @spec type(%{} | keyword() | list() | any()) :: {atom(), any(), any()} | :error
  def type(input) do
    case {input, Enumerable.impl_for(input), Iteraptable.impl_for(input)} do
      {%MapSet{}, _, _} ->
        {MapSet, input, MapSet.new()}

      {%Iteraptor.Array{}, _, _} ->
        {Iteraptor.Array, input, Iteraptor.Array.new()}

      {_, Enumerable.List, _} ->
        {if(Keyword.keyword?(input), do: Keyword, else: List), input, []}

      {_, Enumerable.Map, _} ->
        {Map, input, %{}}

      {_, _, i} when not is_nil(i) ->
        {i.type(input), i.to_enumerable(input), i.to_collectable(input)}

      {_, _, _} ->
        if is_map(input),
          do: {input.__struct__, Map.from_struct(input), %{}},
          else: :error
    end
  end

  @doc """
  Digs the leaf value in the nested keyword / map.

  ## Examples:

      iex> Iteraptor.Utils.dig(%{k1: %{k2: %{k3: :value}}})
      {:ok, {[:k1, :k2, :k3], :value}}
      iex> Iteraptor.Utils.dig([k1: [k2: [k3: :value]]])
      {:ok, {[:k1, :k2, :k3], :value}}
      iex> Iteraptor.Utils.dig([k1: :value, k2: :value])
      {:error, [k1: :value, k2: :value]}
      iex> Iteraptor.Utils.dig([k1: %{k2: [k3: :value]}])
      {:ok, {[:k1, :k2, :k3], :value}}
  """
  @spec dig(%{} | keyword(), keyword()) :: {:ok, {list(), any()}} | {:error, any()}
  def dig(input, acc \\ [])
  def dig(_, {:error, _} = error), do: error

  def dig(input, acc) when is_map(input) do
    case Map.keys(input) do
      [k] -> dig(input[k], [k | acc])
      _ -> {:error, input}
    end
  end

  def dig([{k, v}], acc), do: dig(v, [k | acc])
  def dig(input, _) when is_list(input), do: {:error, input}
  def dig(input, acc), do: {:ok, {:lists.reverse(acc), input}}

  @spec dig!(%{} | keyword(), keyword()) :: {list(), any()} | no_return()
  def dig!(input, acc \\ []) do
    case dig(input, acc) do
      {:ok, result} -> result
      {:error, term} -> raise Unsupported, term: term, function: "Iteraptor.Utils.dig/2"
    end
  end

  @delimiter Application.get_env(:iteraptor, :delimiter, ".")

  @doc false
  @spec delimiter(list()) :: binary()
  def delimiter(opts) when is_list(opts), do: opts[:delimiter] || @delimiter

  @doc false
  @spec smart_convert(any()) :: integer() | binary() | atom()
  def smart_convert(value) do
    case value |> to_string() |> Integer.parse() do
      {value, ""} -> value
      _ -> String.to_existing_atom(value)
    end
  end

  @doc """
  Splits the string by delimiter, possibly converting the keys to symbols.

  ## Examples:

      iex> Iteraptor.Utils.split("a.b.c.d", transform: :none)
      ["a", "b", "c", "d"]
      iex> Iteraptor.Utils.split("a_b_c_d", delimiter: "_")
      ["a", "b", "c", "d"]
      iex> Iteraptor.Utils.split("a.b.c.d", transform: :unsafe)
      [:a, :b, :c, :d]
      iex> Iteraptor.Utils.split("a.b.c.d", transform: :safe)
      [:a, :b, :c, :d]
  """
  @spec split(input :: binary(), opts :: keyword()) :: [binary() | atom()]
  def split(input, opts \\ []) when is_binary(input) do
    result = String.split(input, delimiter(opts))

    case opts[:transform] do
      :safe -> Enum.map(result, &String.to_existing_atom/1)
      :unsafe -> Enum.map(result, &String.to_atom/1)
      _ -> result
    end
  end

  @doc """
  Joins the array of keys into the string using delimiter.

  ## Examples:

      iex> Iteraptor.Utils.join(~w|a b c d|)
      "a.b.c.d"
      iex> Iteraptor.Utils.join(~w|a b c d|, delimiter: "_")
      "a_b_c_d"
  """
  @spec join(Enum.t(), keyword()) :: binary()
  def join(input, opts \\ []) when is_list(input),
    do: Enum.join(input, delimiter(opts))

  @into Application.get_env(:iteraptor, :into, %{})

  @doc """
  Safe put the value deeply into the term nesting structure. Creates
  all the intermediate keys if needed.

  ## Examples:

      iex> Iteraptor.Utils.deep_put_in(%{}, {~w|a b c|a, 42})
      %{a: %{b: %{c: 42}}}
      iex> Iteraptor.Utils.deep_put_in(%{a: %{b: %{c: 42}}}, {~w|a b d|a, :foo})
      %{a: %{b: %{c: 42, d: :foo}}}
      iex> Iteraptor.Utils.deep_put_in(%{a: %{b: [c: 42]}}, {~w|a b d|a, :foo})
      %{a: %{b: [c: 42, d: :foo]}}
      iex> Iteraptor.Utils.deep_put_in(%{a: %{b: [42]}}, {~w|a b|a, :foo})
      %{a: %{b: [42, :foo]}}
      iex> Iteraptor.Utils.deep_put_in(%{a: [:foo, %{b: 42}]}, {~w|a b|a, :foo})
      %{a: [:foo, %{b: 42}, {:b, :foo}]}
  """

  @spec deep_put_in(%{} | keyword(), {list(), any()}, keyword()) :: %{} | keyword()
  def deep_put_in(target, key_value, opts \\ [])

  def deep_put_in(target, {[key], value}, _opts) do
    put_in(target, [key], value)
  end

  def deep_put_in(target, {key, value}, opts) when is_list(key) do
    into = opts[:into] || @into
    [tail | head] = :lists.reverse(key)
    head = :lists.reverse(head)

    {_, target} =
      Enum.reduce(head, {[], target}, fn k, {keys, acc} ->
        keys = keys ++ [k]
        {_, value} = get_and_update_in(acc, keys, &{&1, if(is_nil(&1), do: into, else: &1)})
        {keys, value}
      end)

    case get_in(target, key) do
      nil ->
        {_, result} =
          get_and_update_in(target, head, fn
            nil -> {nil, Enum.into([{tail, value}], into)}
            curr when is_map(curr) -> {curr, Map.put(curr, tail, value)}
            curr when is_list(curr) -> {curr, curr ++ [{tail, value}]}
            curr -> {curr, [curr, {tail, value}]}
          end)

        result

      curr when is_list(curr) ->
        put_in(target, key, curr ++ [value])

      curr when is_map(curr) ->
        put_in(target, key, Map.to_list(curr) ++ [value])

      curr ->
        put_in(target, key, [curr, value])
    end
  end

  @doc """
  Checks if the map/keyword looks like a normal list.

  ## Examples:

      iex> Iteraptor.Utils.quacks_as_list(%{"0" => :foo, 1 => :bar})
      true
      iex> Iteraptor.Utils.quacks_as_list([{:"1", :bar}, {:"0", :foo}])
      true
      iex> Iteraptor.Utils.quacks_as_list(%{foo: :bar})
      false
      iex> Iteraptor.Utils.quacks_as_list(%{"5" => :foo, "1" => :bar})
      false
      iex> Iteraptor.Utils.quacks_as_list(42)
      false
  """
  @spec quacks_as_list(%{} | keyword() | any()) :: true | false
  def quacks_as_list(input) when is_list(input) or is_map(input) do
    input
    |> Enum.map(fn
      {k, _} when is_atom(k) or is_binary(k) or is_number(k) ->
        case k |> to_string() |> Integer.parse() do
          {value, ""} -> value
          _ -> nil
        end

      _ ->
        nil
    end)
    |> Enum.sort() == 0..(Enum.count(input) - 1) |> Enum.to_list()
  end

  def quacks_as_list(_), do: false

  @doc """
  Gently tries to create a linked list out of input, returns input if it
    cannot be safely converted to the list.

  ## Examples:

      iex> Iteraptor.Utils.try_to_list(%{"0" => :foo, 1 => :bar})
      [:foo, :bar]
      iex> Iteraptor.Utils.try_to_list([{:"1", :bar}, {:"0", :foo}])
      [:foo, :bar]
      iex> Iteraptor.Utils.try_to_list(%{foo: :bar})
      %{foo: :bar}
      iex> Iteraptor.Utils.try_to_list(%{"5" => :foo, "1" => :bar})
      %{"5" => :foo, "1" => :bar}
  """
  @spec try_to_list(any()) :: list() | any()
  def try_to_list(input) do
    if quacks_as_list(input) do
      input
      |> Enum.sort(fn {k1, _}, {k2, _} ->
        String.to_integer(to_string(k1)) < String.to_integer(to_string(k2))
      end)
      |> Enum.map(fn {_, v} -> v end)
    else
      input
    end
  end

  @doc """
  Squeezes the nested structure merging same keys.

  ## Examples:

      #iex> Iteraptor.Utils.squeeze([foo: [bar: 42], foo: [baz: 3.14]])
      #[foo: [bar: 42, baz: 3.14]]
      iex> Iteraptor.Utils.squeeze([foo: %{bar: 42}, foo: %{baz: 3.14}])
      [foo: %{bar: 42, baz: 3.14}]
      iex> Iteraptor.Utils.squeeze([foo: %{bar: 42}, foo: :baz])
      [foo: [%{bar: 42}, :baz]]
      iex> Iteraptor.Utils.squeeze([a: [b: [c: 42]], a: [b: [d: 3.14]]])
      [a: [b: [c: 42, d: 3.14]]]
      iex> Iteraptor.Utils.squeeze([a: [b: [c: 42]], a: [b: %{d: 3.14}]])
      [a: [b: [c: 42, d: 3.14]]]
      iex> Iteraptor.Utils.squeeze([a: [b: [c: :foo]], a: [b: [c: 3.14]]])
      [a: [b: [c: [:foo, 3.14]]]]
      iex> Iteraptor.Utils.squeeze([a: [b: [:foo, :bar]], a: [b: [c: 3.14]]])
      [a: [b: [:foo, :bar, {:c, 3.14}]]]
      iex> Iteraptor.Utils.squeeze([a: [:foo, :bar], a: [b: [c: 3.14]]])
      [a: [:foo, :bar, {:b, [c: 3.14]}]]
  """
  @spec squeeze(%{} | keyword() | list() | Access.t(), keyword()) :: %{} | keyword() | list()
  # credo:disable-for-lines:59
  def squeeze(input, opts \\ [])

  def squeeze(input, opts) when is_map(input) or is_list(input) do
    {type, input, into} = type(input)

    {result, _} =
      Enum.reduce(input, {into, 0}, fn
        {k, v}, {acc, orphans} ->
          {_, neu} =
            case type do
              MapSet ->
                {nil, MapSet.put(acc, {k, v})}

              Iteraptor.Array ->
                {nil, Iteraptor.Array.append(acc, {k, v})}

              List ->
                {nil, [{k, v} | acc]}

              _ ->
                get_and_update_in(acc, [k], fn
                  nil ->
                    {nil, v}

                  map when is_map(map) ->
                    case v do
                      %{} -> {map, Map.merge(map, v)}
                      _ -> {map, [map, v]}
                    end

                  list when is_list(list) ->
                    case v do
                      [] -> {list, list}
                      [_ | _] -> {list, list ++ v}
                      %{} -> {list, list ++ Map.to_list(v)}
                      _ -> {list, list ++ [v]}
                    end

                  other ->
                    {other, [other, v]}
                end)
            end

          {neu, orphans}

        v, {acc, orphans} ->
          case type do
            Keyword -> {[v | acc], orphans}
            List -> {[v | acc], orphans}
            Map -> {Map.put(acc, orphans, v), orphans + 1}
          end
      end)

    result =
      result
      |> Enum.into(into, fn
        {k, v} when is_list(v) -> {k, v |> squeeze(opts) |> :lists.reverse()}
        {k, v} -> {k, squeeze(v, opts)}
        v -> v
      end)
      |> try_to_list()

    if opts[:structs] == :keep && is_map(result) and type != Map,
      do: struct(type, result),
      else: result
  end

  def squeeze(input, _opts), do: input

  @doc false
  def struct_checker(env, _bytecode), do: env.module.__struct__
end
