defmodule Iteraptor.Iteraptable do
  @moduledoc """
  `use Iteraptor.Iteraptable` inside structs to make them both
  [`Enumerable`](http://elixir-lang.org/docs/stable/elixir/Enumerable.html) and
  [`Collectable`](http://elixir-lang.org/docs/stable/elixir/Collectable.html) and
  implement the [`Access`](https://hexdocs.pm/elixir/Access.html#content) behaviour:

  ## Usage

  Use the module within the struct of your choice and this struct will be
  automagically granted `Enumerable` and `Collectable` protocols implementations.
  """

  @codepieces [
    enumerable:
      quote do

        defimpl Enumerable, for: __MODULE__ do
          def slice(enumerable) do
            {:error, __MODULE__}
          end

          def count(map) do
            {:ok, map |> Map.from_struct |> map_size} # do not count :__struct__
          end

          def member?(_, {:__struct__, _}) do
            {:ok, false}
          end

          def member?(map, {key, value}) do
            {:ok, match?({:ok, ^value}, :maps.find(key, map))}
          end

          def member?(_, _) do
            {:ok, false}
          end

          def reduce(map, acc, fun) do
            do_reduce((map |> Map.from_struct |> :maps.to_list), acc, fun)
          end

          defp do_reduce(_,       {:halt, acc}, _fun),   do: {:halted, acc}
          defp do_reduce(list,    {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(list, &1, fun)}
          defp do_reduce([],      {:cont, acc}, _fun),   do: {:done, acc}
          defp do_reduce([h | t], {:cont, acc}, fun),    do: do_reduce(t, fun.(h, acc), fun)
        end

      end,

    collectable:
      quote do

        defimpl Collectable, for: __MODULE__ do
          def into(original) do
            {original, fn
              map, {:cont, {k, v}} -> :maps.put(k, v, map)
              map, :done -> map
              _,   :halt -> :ok
            end}
          end
        end

      end,

    access:
      quote do
        @behaviour Access

        def fetch(term, key) do
          try do
            {:ok, term.key}
          rescue
            e in KeyError -> :error
          end
        end

        def get(term, key, default \\ nil) do
          case fetch(term, key) do
            {:ok, value} -> value
            :error -> default
          end
        end

        def get_and_update(term, key, fun) do
          current = get(term, key)

          case fun.(current) do
            {get, update} -> {get, %{term | key => update}}
            :pop -> {current, %{term | key => nil}}
            other ->
              raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
          end
        end

        def pop(term, key) do
          get_and_update(term, key, fn _ -> :pop end)
        end
      end
  ]

  @doc """
  Allows to enable iterating features on structs with `use Iteraptor.Iteraptable`

  ## Parameters

  - `opts`: `Keyword` that currently might consist of `skip: collectable`
  to make `Iteraptor` to implement `Enumerable` protocol _only_

  ## Examples

      iex> %Iteraptor.Struct{field: 42}
      ...>   |> Enum.map(fn {k, v} -> {k, v * 2} end)
      ...>   |> Enum.into(%Iteraptor.Struct{})
      %Iteraptor.Struct{field: 84}
  """
  defmacro __using__(opts \\ []) do
    Enum.reduce(~w|enumerable collectable access|a, [], fn type, acc ->
      if opts[:skip] == type, do: acc, else: [@codepieces[type] | acc]
    end)
  end
end
