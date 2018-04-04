defmodule Iteraptor.Extras do
  @moduledoc ~S"""
    Extra functions to deal with enumerables.
  """

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
  """
  def each_cons(list, n \\ 2, acc \\ [])
  def each_cons([], _, acc), do: acc
  def each_cons(list, n, acc) when is_list(list) and length(list) < n,
    do: acc |> Enum.reverse
  def each_cons(list = [_ | tail], n, acc),
    do: each_cons(tail, n, [Enum.take(list, n)|acc])
  def each_cons(list, n, acc) when is_map(list),
    do: each_cons(list |> Enum.to_list, n, acc)
end
