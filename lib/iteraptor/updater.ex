defmodule Iteraptor.Updater do

  defmodule Unsupported do
    defexception [:term, :function, :message]

    def exception(term: term, function: function) do
      message = "Unsupported term #{inspect term} in call to #{function}."
      %Iteraptor.Updater.Unsupported{term: term, function: function, message: message}
    end
  end

  @moduledoc "Helper functions to update nested terms"

  @doc """
  Determines the type of the given term.

  ## Examples:

      iex> Iteraptor.Updater.type(%{foo: :bar})
      {Map, %{}}
      iex> Iteraptor.Updater.type([foo: :bar])
      {Keyword, []}
      iex> Iteraptor.Updater.type([{:foo, :bar}])
      {Keyword, []}
      iex> Iteraptor.Updater.type(~w|foo bar|a)
      {List, []}
      iex> Iteraptor.Updater.type(42)
      {:invalid, nil}
      iex> Iteraptor.Updater.type(%Struct1{field1: 42})
      {Struct1, %Struct1{field1: nil}}
  """
  @spec type(Map.t | Keyword.t | List.t | any()) :: {atom(), %{} | [] | nil}
  def type(input) do
    case Enumerable.impl_for(input) do
      Enumerable.List ->
        {(if Keyword.keyword?(input), do: Keyword, else: List), []}
      Enumerable.Map ->
        {Map, %{}}
      _ ->
      # FIXME struct instantiation is potentially dangerous
        if is_map(input),
          do: {input.__struct__, struct(input.__struct__)},
          else: {:invalid, nil}
    end
  end

  @doc """
  Digs the leaf value in the nested keyword / map.

  ## Examples:

      iex> Iteraptor.Updater.dig(%{k1: %{k2: %{k3: :value}}})
      {:ok, {[:k1, :k2, :k3], :value}}
      iex> Iteraptor.Updater.dig([k1: [k2: [k3: :value]]])
      {:ok, {[:k1, :k2, :k3], :value}}
      iex> Iteraptor.Updater.dig([k1: :value, k2: :value])
      {:error, [k1: :value, k2: :value]}
      iex> Iteraptor.Updater.dig([k1: %{k2: [k3: :value]}])
      {:ok, {[:k1, :k2, :k3], :value}}
  """
  @spec dig(Map.t | Keyword.t, List.t) :: {:ok, {List.t, any()}} | {:error, any()}
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

  @spec dig!(Map.t | Keyword.t, List.t) :: {List.t, any()} | no_return()
  def dig!(input, acc \\ []) do
    case dig(input, acc) do
      {:ok, result} -> result
      {:error, term} -> raise Unsupported, term: term, function: :dig
    end
  end

  @delimiter "."

  @doc """
  Splits the string by delimiter, possibly converting the keys to symbols.

  ## Examples:

      iex> Iteraptor.Updater.split("a.b.c.d", transform: :none)
      ["a", "b", "c", "d"]
      iex> Iteraptor.Updater.split("a_b_c_d", delimiter: "_")
      ["a", "b", "c", "d"]
      iex> Iteraptor.Updater.split("a.b.c.d", transform: :unsafe)
      [:a, :b, :c, :d]
      iex> Iteraptor.Updater.split("a.b.c.d", transform: :safe)
      [:a, :b, :c, :d]
  """
  @spec split(binary(), Keyword.t) :: List.t
  def split(input, opts \\ []) when is_binary(input) do
    result = String.split(input, opts[:delimiter] || @delimiter)
    case opts[:transform] do
      :safe -> Enum.map(result, &String.to_existing_atom/1)
      :unsafe -> Enum.map(result, &String.to_atom/1)
      _ -> result
    end
  end

  @doc """
  Joins the array of keys into the string using delimiter.

  ## Examples:

      iex> Iteraptor.Updater.join(~w|a b c d|)
      "a.b.c.d"
      iex> Iteraptor.Updater.join(~w|a b c d|, delimiter: "_")
      "a_b_c_d"
  """
  @spec join(List.t, Keyword.t) :: binary()
  def join(input, opts \\ []) when is_list(input) do
    Enum.join(input, opts[:delimiter] || @delimiter)
  end

  @into %{}

  @doc """
  Safe put the value deeply into the term nesting structure. Creates
  all the intermediate keys if needed.

  ## Examples:

      iex> Iteraptor.Updater.deep_put_in(%{}, {~w|a b c|a, 42})
      %{a: %{b: %{c: 42}}}
      iex> Iteraptor.Updater.deep_put_in(%{a: %{b: %{c: 42}}}, {~w|a b d|a, :foo})
      %{a: %{b: %{c: 42, d: :foo}}}
      iex> Iteraptor.Updater.deep_put_in(%{a: %{b: [c: 42]}}, {~w|a b d|a, :foo})
      %{a: %{b: [c: 42, d: :foo]}}
      iex> Iteraptor.Updater.deep_put_in(%{a: %{b: [42]}}, {~w|a b|a, :foo})
      %{a: %{b: [42, :foo]}}
      iex> Iteraptor.Updater.deep_put_in(%{a: [:foo, %{b: 42}]}, {~w|a b|a, :foo})
      %{a: [:foo, %{b: 42}, {:b, :foo}]}
  """

  @spec deep_put_in(Map.t | Keyword.t, {List.t, any()}, Keyword.t) :: Map.t | Keyword.t
  def deep_put_in(target, {key, value}, opts \\ []) when is_list(key) do
    into = opts[:into] || @into
    [tail | head] = :lists.reverse(key)
    head = :lists.reverse(head)

    {_, target} =
      Enum.reduce(head, {[], target}, fn k, {keys, acc} ->
        keys = keys ++ [k]
        {_, value} =
          get_and_update_in(acc, keys, &{&1, (if is_nil(&1), do: into, else: &1)})
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
      curr when is_list(curr) -> put_in(target, key, curr ++ [value])
      curr when is_map(curr) -> put_in(target, key, Map.to_list(curr) ++ [value])
      curr -> put_in(target, key, [curr, value])
    end
  end

  @doc """
  Checks if the map/keyword looks like a normal list.

  ## Examples:

      iex> Iteraptor.Updater.quacks_as_list(%{"0" => :foo, 1 => :bar})
      true
      iex> Iteraptor.Updater.quacks_as_list([{:"1", :bar}, {:"0", :foo}])
      true
      iex> Iteraptor.Updater.quacks_as_list(%{foo: :bar})
      false
      iex> Iteraptor.Updater.quacks_as_list(%{"5" => :foo, "1" => :bar})
      false
      iex> Iteraptor.Updater.quacks_as_list(42)
      false
  """
  @spec quacks_as_list(Map.t | Keyword.t | any()) :: true | false
  def quacks_as_list(input) when is_list(input) or is_map(input) do
    input
    |> Enum.map(fn
         {k, _} ->
           case k |> to_string() |> Integer.parse() do
             {value, ""} -> value
             _ -> nil
           end
         _ -> nil
       end)
    |> Enum.sort() == (0..Enum.count(input) - 1 |> Enum.to_list)
  end
  def quacks_as_list(_), do: false

  @doc """
  Gently tries to create a linked list out of input, returns input if it
    cannot be safely converted to the list.

  ## Examples:

      iex> Iteraptor.Updater.try_to_list(%{"0" => :foo, 1 => :bar})
      [:foo, :bar]
      iex> Iteraptor.Updater.try_to_list([{:"1", :bar}, {:"0", :foo}])
      [:foo, :bar]
      iex> Iteraptor.Updater.try_to_list(%{foo: :bar})
      %{foo: :bar}
      iex> Iteraptor.Updater.try_to_list(%{"5" => :foo, "1" => :bar})
      %{"5" => :foo, "1" => :bar}
  """
  @spec try_to_list(any()) :: List.t | any()
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

      #iex> Iteraptor.Updater.squeeze([foo: [bar: 42], foo: [baz: 3.14]])
      #[foo: [bar: 42, baz: 3.14]]
      iex> Iteraptor.Updater.squeeze([foo: %{bar: 42}, foo: %{baz: 3.14}])
      [foo: %{bar: 42, baz: 3.14}]
      iex> Iteraptor.Updater.squeeze([a: [b: [c: 42]], a: [b: [d: 3.14]]])
      [a: [b: [c: 42, d: 3.14]]]
  """
  @spec squeeze(Map.t | Keyword.t | List.t) :: Map.t | Keyword.t | List.t
  def squeeze(input) when is_map(input) or is_list(input) do
    {type, into} = type(input)

    {result, _} =
      Enum.reduce(input, {into, 0}, fn
        {k, v}, {acc, orphans} ->
          {_, neu} =
            get_and_update_in(acc, [k], fn
              nil -> {nil, v}
              map when is_map(map) -> {map, Map.merge(map, v)}
              list when is_list(list) -> {list, list ++ v}
            end)
          {neu, orphans}
        v, {acc, orphans} ->
          case type do
            Keyword -> {[v | acc], orphans} # FIXME raise? this cannot happen
            List -> {[v | acc], orphans}
            Map -> {Map.put(acc, orphans, v), orphans + 1}
          end
      end)

    {_type, into} = type(result)
    result
    |> Enum.map(fn
         {k, v} when is_list(v) -> {k, v |> squeeze() |> :lists.reverse()}
         {k, v} -> {k, squeeze(v)}
         v -> v
       end)
    |> Enum.into(into)
  end
  def squeeze({_, v}), do: v
  def squeeze(input), do: input
end
