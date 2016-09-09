defmodule Iteraptor do
  @joiner "."

  @doc """
    # iex> [:a, 42] |> Iteraptor.flatten
    # [:a, 42]

    # iex> %{a: 42} |> Iteraptor.flatten
    # %{a: 42}

    # iex> %{a: %{b: 42}, d: 42} |> Iteraptor.flatten
    # %{"a.b": 42, d: 42}

    # iex> %{a: [:b, 42], d: 42} |> Iteraptor.flatten
    # %{"a.0": :b, "a.1": 42, d: 42}

    # iex> %{a: %{b: [:c, 42]}, d: 42} |> Iteraptor.flatten
    # %{"a.b.0": :c, "a.b.1": 42, d: 42}

    iex> %{a: %{b: %{c: 42}}} |> Iteraptor.flatten
    %{"a.b.c": 42}

    # iex> %{a: %{b: %{c: 42}}, d: 42} |> Iteraptor.flatten
    # %{"a.b.c": 42, d: 42}
  """

  def flatten(input, joiner \\ @joiner)

  def flatten(input, joiner) when is_map(input) do
    process(input, joiner)
      |> List.flatten
      |> Enum.into(%{})
  end

  def flatten(input, joiner) when is_list(input) do
    process(input, joiner)
      |> List.flatten
  end

  ##############################################################################

  defp process(input, joiner \\ @joiner, prefix \\ "")

  ##############################################################################

  defp process({key, value}, joiner, prefix) when is_list(value) do
    IO.puts 1
    prefix = join(prefix, key, joiner)
    for { v, k } <- (value |> Enum.with_index) do
      { join(prefix, k, joiner), process(v, joiner, prefix) }
    end
  end

  defp process({key, value}, joiner, prefix) when is_map(value) do
    IO.puts 2
    prefix = join(prefix, key, joiner)
    for { k, v } <- value do
      { join(prefix, k, joiner), process(v, joiner, prefix) }
    end
  end

  defp process({key, value}, joiner, prefix) do
    IO.puts "#{inspect(key)} ⇒ #{inspect(value)} ⇒ [#{prefix}]"
    { join(prefix, key, joiner), process(value, joiner, prefix) }
  end

  ##############################################################################

  defp process(input, joiner, prefix) when is_map(input) do
    IO.puts 3
    input |> Enum.map(fn {k, v} -> process({k, v}, joiner, prefix) end)
  end

  defp process(input, joiner, prefix) when is_list(input) do
    IO.puts 4
    input |> Enum.map(fn e -> process(e, joiner, prefix) end)
  end

  ##############################################################################

  defp process(input, _, prefix) do
    IO.puts 5
    input
  end

  ##############################################################################

  defp join(l, "", joiner) do
    String.to_atom(to_string(l))
  end

  defp join("", r, joiner) do
    String.to_atom(to_string(r))
  end

  defp join(l, r, joiner) do
    String.to_atom(to_string(l) <> joiner <> to_string(r))
  end
end
