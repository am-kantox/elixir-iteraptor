defmodule Iteraptor do
  @joiner "."

  @doc """
    iex> [:a, 42] |> Iteraptor.to_flatmap
    %{"0": :a, "1": 42}

    iex> %{a: 42} |> Iteraptor.to_flatmap
    %{a: 42}

    iex> %{a: 42, b: 42} |> Iteraptor.to_flatmap
    %{a: 42, b: 42}

    iex> %{a: %{b: 42}, d: 42} |> Iteraptor.to_flatmap
    %{"a.b": 42, d: 42}

    iex> %{a: [:b, 42], d: 42} |> Iteraptor.to_flatmap
    %{"a.0": :b, "a.1": 42, d: 42}

    iex> %{a: %{b: [:c, 42]}, d: 42} |> Iteraptor.to_flatmap
    %{"a.b.0": :c, "a.b.1": 42, d: 42}

    iex> %{a: %{b: 42}} |> Iteraptor.to_flatmap
    %{"a.b": 42}

    iex> %{a: %{b: %{c: 42}}} |> Iteraptor.to_flatmap
    %{"a.b.c": 42}

    iex> %{a: %{b: %{c: 42}}, d: 42} |> Iteraptor.to_flatmap
    %{"a.b.c": 42, d: 42}

    iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
    %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
  """

  def to_flatmap(input, joiner \\ @joiner) when is_map(input) or is_list(input) do
    process(input, joiner)
  end

  ##############################################################################

  defp process(input, joiner, prefix \\ "", acc \\ %{})

  ##############################################################################

  defp process(input, joiner, prefix, acc) when is_map(input) do
    input |> Enum.reduce(acc, fn({k, v}, memo) ->
      prefix = join(prefix, k, joiner)
      if is_map(v) or is_list(v) do
        process(v, joiner, prefix, memo)
      else
        Map.put memo, prefix, v
      end
    end)
  end

  defp process(input, joiner, prefix, acc) when is_list(input) do
    input
      |> Enum.with_index
      |> Enum.map(fn({k, v}) -> {v, k} end)
      |> Enum.into(%{})
      |> process(joiner, prefix, acc)
  end

  ##############################################################################

  defp join(l, "", _) do
    String.to_atom(to_string(l))
  end

  defp join("", r, _) do
    String.to_atom(to_string(r))
  end

  defp join(l, r, joiner) do
    String.to_atom(to_string(l) <> joiner <> to_string(r))
  end
end
