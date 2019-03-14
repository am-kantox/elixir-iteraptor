defmodule Iteraptor.Array do
  @moduledoc """
  Array emulation implementing `Access` behaviour. Index in array is zero-based.

  `Array` is the "go to" array data structure in Elixir. An array can be
    constructed using `Array.new/{0,1}`:

      iex> Iteraptor.Array.new()
      #Array<[]>

      iex> Iteraptor.Array.new(2)
      #Array<[nil, nil]>

      iex> Iteraptor.Array.new([:foo, :bar])
      #Array<[:foo, :bar]>

  An array can contain any kind of elements, and elements in an array don't have
    to be of the same type. By definition, arrays have _keys_ in `0..size-1` range.
  Arrays are implicitly expandable, which means adding an element at index `100`
    to the array currently containing 1 element would increase the size of the
    array to `100`.

      iex> array = Iteraptor.Array.new([:foo])
      iex> Iteraptor.Array.set(array, 3, :bar)
      #Array<[:foo, nil, nil, :bar]>

  An `Array` is represented internally using the `%Array{}` struct. Note that,
    however, the struct fields are private and must not be accessed directly;
    use the functions in this module to perform operations on arrays.

  `Array`s can also be constructed starting from other collection-type data
  structures: for example, see `Array.new/1` or `Enum.into/2`.

      iex> Enum.into([1, 2, 3], Iteraptor.Array.new())
      #Array<[1, 2, 3]>

  `Array`s do implement `Access` behaviour.

      iex> array = Iteraptor.Array.new([%{foo: 42}, %{bar: :baz}])
      iex> get_in(array, [0, :foo])
      42

  """

  # Arrays have an underlying Map. Array elements are values of said map,
  # indices are keys.

  @type value :: term

  @opaque t(value) :: %__MODULE__{map: %{required(non_neg_integer) => value}}
  @type t :: t(term)

  defstruct map: %{}, version: 1

  @behaviour Access

  alias Iteraptor.Array

  @doc """
  Returns a new array.
  ## Examples
      iex> Iteraptor.Array.new()
      #Array<[]>
  """
  @spec new :: t
  def new(), do: %Array{}

  @spec new(integer() | Enum.t()) :: t
  def new(enumerable)

  @doc """
  Creates an array of the given length.
  ## Examples
      iex> Iteraptor.Array.new(3)
      #Array<[nil, nil, nil]>
  """
  @spec new :: t
  def new(n) when is_integer(n) and n >= 0,
    do: Iteraptor.Array.new(List.duplicate(nil, n))

  @doc """
  Creates an array from an enumerable.
  ## Examples
      iex> Iteraptor.Array.new([:foo, :bar, 42])
      #Array<[:foo, :bar, 42]>
  """

  def new(%__MODULE__{} = array), do: array

  def new(enumerable) do
    list = Enum.to_list(enumerable)

    map =
      0..(length(list) - 1)
      |> Enum.zip(list)
      |> Enum.into(%{})

    %Array{map: map}
  end

  @doc """
  Creates an array from an enumerable via the transformation function.
  ## Examples
      iex> Iteraptor.Array.new([1, 2, 3], fn x -> 2 * x end)
      #Array<[2, 4, 6]>
  """
  @spec new(Enum.t(), (term -> val)) :: t(val) when val: value
  def new(enumerable, transform) when is_function(transform, 1) do
    list =
      enumerable
      |> Enum.map(&transform.(&1))
      |> Enum.to_list()

    map =
      0..(length(list) - 1)
      |> Enum.zip(list)
      |> Enum.into(%{})

    %Array{map: map}
  end

  @doc """
  Appends another enumerable to the array.
  ## Examples
      iex> array = Iteraptor.Array.new([1, 2, 3])
      iex> Iteraptor.Array.append(array, [4, 5])
      #Array<[1, 2, 3, 4, 5]>
  """
  @spec append(t(val1), any()) :: t(val1) when val1: value
  def append(%Array{map: map} = array, other) do
    index = map |> Map.keys() |> List.last() || -1

    map =
      if Enumerable.impl_for(other) do
        appender =
          other
          |> Enum.reduce({index + 1, []}, fn e, {i, acc} -> {i + 1, [{i, e} | acc]} end)
          |> elem(1)
          |> Enum.reverse()
          |> Enum.into(%{})

        Map.merge(map, appender)
      else
        Map.put(map, index + 1, other)
      end

    %Array{array | map: map}
  end

  @doc """
  Returns the `value` at `index` in `array`, or `default` if index is out of array bounds.

  ## Examples
      iex> array = Iteraptor.Array.new([42])
      iex> Iteraptor.Array.get(array, 0)
      42
      iex> Iteraptor.Array.get(array, 2, 42)
      42
  """
  @spec get(t(val), non_neg_integer(), any()) :: val when val: value
  def get(array, index, default \\ nil)
  def get(%Array{map: map}, index, default) when index < 0 or index >= map_size(map), do: default
  def get(%Array{map: map}, index, _default), do: map[index]

  @doc """
  Pops (deletes) `value` at `index` from `array`, setting the value at the
    respective index to `nil`.
  Returns a tuple containing the value removed and the new array.

  ## Examples
      iex> array = Iteraptor.Array.new([1, 2, 3])
      iex> {elem, array} = Iteraptor.Array.pop(array, 1)
      iex> elem
      2
      iex> array
      #Array<[1, nil, 3]>
  """
  @impl Access
  @spec pop(t(val1), non_neg_integer()) :: {val1, t(val1)} when val1: value
  def pop(%Array{map: map} = array, index) do
    value = map[index]
    {value, %{array | map: Map.put(map, index, nil)}}
  end

  @doc """
  Sets the `value` at `index` in `array`, expanding the array if necessary.
  Returns a new array.

  ## Examples
      iex> array = Iteraptor.Array.new([42])
      iex> Iteraptor.Array.set(array, 0, :foo)
      #Array<[:foo]>
      iex> Iteraptor.Array.set(array, 2, :bar)
      #Array<[42, nil, :bar]>
  """
  @spec set(t(val), non_neg_integer(), val) :: t(val) when val: value
  def set(%Array{map: map} = array, index, value) do
    size = Array.size(array)

    map =
      if size > index do
        Map.put(map, index, value)
      else
        fill = Enum.reverse([value | List.duplicate(nil, index - size)])
        Map.merge(map, Enum.into(Enum.zip(size..index, fill), %{}))
      end

    %Array{array | map: map}
  end

  @doc """
  Trims `nil` values from the tail of the `Array`. Returns a trimmed array.

  ## Examples
      iex> array = Iteraptor.Array.new([42, nil, nil])
      #Array<[42, nil, nil]>
      iex> Iteraptor.Array.trim(array)
      #Array<[42]>
  """
  @spec trim(t(val)) :: t(val) when val: value
  def trim(%Array{map: map} = array) do
    map =
      map
      |> Enum.reverse()
      |> Enum.drop_while(fn
        {_, nil} -> true
        _ -> false
      end)
      |> Enum.reverse()
      |> Enum.into(%{})

    %Array{array | map: map}
  end

  @doc """
  Returns the number of elements in `array`.
  ## Examples
      iex> Iteraptor.Array.size(Iteraptor.Array.new([1, 2, 3]))
      3
  """
  @spec size(t) :: non_neg_integer
  def size(%Array{map: map}), do: map_size(map)

  @doc """
  Converts `array` to a list.
  ## Examples
      iex> Iteraptor.Array.to_list(Iteraptor.Array.new([1, 2, 3]))
      [1, 2, 3]
  """
  @spec to_list(t(val)) :: [val] when val: value
  def to_list(%Array{map: map}), do: Map.values(map)

  @doc """
  Converts a tuple given as parameter to `array`.
  ## Examples
      iex> Iteraptor.Array.from_tuple({1, 2, 3})
      #Array<[1, 2, 3]>
  """
  @spec from_tuple(tuple :: tuple()) :: t(val) when val: value
  def from_tuple(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> Array.new()

  ### Access behaviour

  @doc false
  @impl true
  def fetch(%Array{map: map}, index), do: Map.fetch(map, index)

  @doc false
  @impl true
  def get_and_update(%Array{map: map} = array, index, function) do
    case function.(map[index]) do
      :pop -> Array.pop(array, index)
      {get_value, update_value} -> {get_value, Array.set(array, index, update_value)}
    end
  end

  defimpl Enumerable do
    def count(array) do
      {:ok, Array.size(array)}
    end

    def member?(%Array{map: map}, val) do
      {:ok,
       !!Enum.find(map, fn
         {_, ^val} -> true
         {_, _} -> false
       end)}
    end

    def slice(array),
      do: {:ok, Array.size(array), &Enumerable.List.slice(Array.to_list(array), &1, &2)}

    def reduce(array, acc, fun),
      do: Enumerable.List.reduce(Array.to_list(array), acc, fun)
  end

  defimpl Collectable do
    def into(array) do
      fun = fn
        list, {:cont, x} -> [x | list]
        list, :done -> Array.append(array, Enum.reverse(list))
        _, :halt -> :ok
      end

      {[], fun}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(array, opts) do
      opts = %Inspect.Opts{opts | charlists: :as_lists}
      concat(["#Array<", Inspect.List.inspect(Array.to_list(array), opts), ">"])
    end
  end
end
