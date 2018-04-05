defmodule Iteraptor.Extras do
  @moduledoc ~S"""
    Extra functions to deal with enumerables.
  """

  @doc """
  Deep store the value into the nested structure. Behaves as a [proposed
    but rejected in ruby core](https://bugs.ruby-lang.org/issues/11747)
    `Hash#bury`.

  ## Examples:

      iex> Iteraptor.Extras.bury(%{foo: :bar}, ~w|a b c d|a, 42)
      %{a: %{b: %{c: %{d: 42}}}, foo: :bar}
      iex> Iteraptor.Extras.bury([foo: :bar], ~w|a b c d|a, 42)
      [a: [b: [c: [d: 42]]], foo: :bar]
      iex> Iteraptor.Extras.bury(%{foo: :bar}, ~w|a b c d|a, 42, into: :keyword)
      %{a: [b: [c: [d: 42]]], foo: :bar}
      iex> Iteraptor.Extras.bury(42, ~w|a b c d|a, 42)
      ** (Iteraptor.Utils.Unsupported) Unsupported term 42 in call to Iteraptor.Extras.bury/4.
  """
  @spec bury(Access.t(), List.t(), any(), :default | :map | :keyword | Keyword.t()) :: Access.t()
  def bury(term, key, value, opts \\ [into: :default])

  def bury(term, key, value, into: :default) do
    {type, into} = Iteraptor.Utils.type(term)

    case type do
      :invalid ->
        raise Iteraptor.Utils.Unsupported, term: term, function: "Iteraptor.Extras.bury/4"

      _ ->
        bury(term, key, value, into: into)
    end
  end

  def bury(term, key, value, into: :map), do: bury(term, key, value, into: %{})
  def bury(term, key, value, into: :keyword), do: bury(term, key, value, into: [])

  def bury(term, key, value, into: into),
    do: Iteraptor.Utils.deep_put_in(term, {key, value}, into: into)

  @doc ~S"""
  Behaves as `Enum.each_cons(n)` in ruby. Iterates the input producing the list of cons.
    Gracefully stolen from https://groups.google.com/forum/#!topic/elixir-lang-core/LAK23vaJgvE

  ## Examples

      iex> 'letters' |> Iteraptor.Extras.each_cons
      ['le', 'et', 'tt', 'te', 'er', 'rs']
      iex> 'letters' |> Iteraptor.Extras.each_cons(4)
      ['lett', 'ette', 'tter', 'ters']
      iex> 1..6 |> Iteraptor.Extras.each_cons(4)
      [[1,2,3,4], [2,3,4,5], [3,4,5,6]]
      iex> "letters" |> Iteraptor.Extras.each_cons(3)
      ["let", "ett", "tte", "ter", "ers"]
  """

  @spec each_cons(List.t() | Map.t() | binary(), integer(), List.t()) :: List.t()

  def each_cons(list, n \\ 2, acc \\ [])
  def each_cons([], _, acc), do: acc
  def each_cons(list, n, acc) when is_list(list) and length(list) < n, do: Enum.reverse(acc)
  def each_cons([_ | tail] = list, n, acc), do: each_cons(tail, n, [Enum.take(list, n) | acc])
  def each_cons(map, n, acc) when is_map(map), do: each_cons(Enum.to_list(map), n, acc)

  def each_cons(string, n, acc) when is_binary(string) do
    string
    |> to_charlist()
    |> each_cons(n, acc)
    |> Enum.map(&to_string/1)
  end
end
