defmodule Iteraptor.Iteraptable do
  @codepieces [
    enumerable: """

      defimpl Enumerable, for: ★ do
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

    """,
    collectable: """

      defimpl Collectable, for: ★ do
        def into(original) do
          {original, fn
            map, {:cont, {k, v}} -> :maps.put(k, v, map)
            map, :done -> map
            _,   :halt -> :ok
          end}
        end
      end

    """
  ]

  @doc """
  Allows to enable iterating features on structs with `use Iteraptor.Iteraptable`

  ## Examples:

      iex> %Iteraptor.Struct{field: 42}
      ...>   |> Enum.map(fn {k, v} -> {k, v * 2} end)
      ...>   |> Enum.into(%Iteraptor.Struct{})
      %Iteraptor.Struct{field: 84}
  """
  defmacro __using__(opts \\ []) do
    code = ([:enumerable, :collectable] |> Enum.reduce("", fn type, acc ->
      acc <> (if opts[:skip] == type, do: "", else: @codepieces[type])
    end))
    quote do
      impls = unquote(code) |> String.replace("★", to_string(__MODULE__))
      Code.eval_string(impls, [], __ENV__)
    end
  end
end

# this is a temporary glitch/artifact of protocol consolidation does not work
#    properly in test environment: basically I need this for tests, sorry :)
defmodule Iteraptor.Struct do
  @fields [field: nil]

  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end
