defmodule Iteraptor.AST do
  @moduledoc """
  `Iteraptor.AST` module traverses AST, allowing `map`, `reduce` and family.
  """

  @doc """
  Reduces the AST with an accumulator.

  ## Parameters

  - `input`: the AST to traverse
  - `acc`: the accumulator
  - `fun`: the function to be called on the tree element
  - `opts`: the options to be passed to the iteration
    - `yield`: `:all | nil` what to yield; _default:_ `nil`
    for yielding _values only_.

  ## Examples

      iex> ":math.sin(42 * a / (3.14 * b)) > c"
      ...> |> Iteraptor.AST.reduce([], fn
      ...>      {var, _, val}, acc when is_atom(val) -> [var | acc]
      ...>      _, acc -> acc
      ...>    end)
      ...> |> Enum.reverse()
      ~w|a b c|a
  """

  def reduce(input, acc, fun, opts \\ []), do: do_traverse(input, acc, fun, opts)

  ##############################################################################

  defp do_traverse(string, acc, fun, opts) when is_binary(string) do
    with {:ok, ast} = Code.string_to_quoted(string),
      do: do_traverse(ast, acc, fun, opts)
  end

  defp do_traverse({var, meta, val}, acc, fun, _opts)
    when is_atom(var) and is_atom(val), do: fun.({var, meta, val}, acc)

  defp do_traverse({operator, meta, ast}, acc, fun, opts) do
    acc =
      Iteraptor.reduce(ast, acc, fn
        {_, {term, meta, ast}}, acc when is_list(ast) ->
          acc = do_traverse(ast, acc, fun, opts)
          if opts[:yield] == :all, do: fun.({term, meta, ast}, acc), else: acc
        {_, {var, meta, ast}}, acc when is_atom(var) ->
          fun.({var, meta, ast}, acc)
        _, acc ->
          acc
      end, opts)
   if opts[:yield] == :all || is_atom(ast),
     do: fun.({operator, meta, ast}, acc), else: acc
  end

  defp do_traverse(ast, acc, fun, opts) when is_list(ast) do
#    fun =
#      if opts[:yield] == :all do
#        &do_traverse(&1, fun.(&1, &2), fun, opts)
#      else
#        &do_traverse(&1, &2, fun, opts)
#      end

    Enum.reduce(ast, acc, &do_traverse(&1, &2, fun, opts))
  end

  defp do_traverse(term, acc, fun, opts) do
    if opts[:yield] == :all, do: fun.(term, acc), else: acc
  end

end
