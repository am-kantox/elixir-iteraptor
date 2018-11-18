defprotocol Iteraptable do
  @since "1.5.0"
  @moduledoc """
  The protocol specifying how the respective struct might be used within `Iteraptor`.

  **Experimental.** By implementing this protocol one might change the behaviour of
  nested objects regarding how they should be iterated through.
  """

  @spec type(term :: any()) :: atom()
  @doc "Returns a type understood by `Iteraptable`"
  def type(term)

  @spec to_enumerable(term :: any()) :: Enumerable.t
  @doc "Converts a term to an enumerable"
  def to_enumerable(term)

  @spec to_collectable(term :: any()) :: Collectable.t
  @doc "Converts a term to a collectable"
  def to_collectable(term)

  @spec name(term :: any()) :: binary()
  @doc "Returns a name of the term to be represented in flatmaps"
  def name(term)
end

defimpl Iteraptable, for: Date do
  def name(_term), do: "s·date"
  def type(_term), do: Date
  if Version.compare(System.version(), "1.8.0") == :lt  do
    def to_enumerable(term), do: %{struct_date: Date.to_iso8601(term)}
  else
    def to_enumerable(term), do: %{struct_date: Date.to_iso8601(term)}
    # def to_enumerable(term), do: %{s·date: Date.to_iso8601(term)}
  end
  def to_collectable(_term), do: %{}
end

defimpl Iteraptable, for: Time do
  def name(_term), do: "s·time"
  def type(_term), do: Time
  if Version.compare(System.version(), "1.8.0") == :lt  do
    def to_enumerable(term), do: %{struct_time: Time.to_iso8601(term)}
  else
    def to_enumerable(term), do: %{struct_time: Time.to_iso8601(term)}
    # def to_enumerable(term), do: %{s·time: Time.to_iso8601(term)}
  end
  def to_collectable(_term), do: %{}
end
