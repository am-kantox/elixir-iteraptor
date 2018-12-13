defmodule Iteraptable do
  @since "1.5.0"
  @moduledoc """
  The behaviour specifying how the respective struct might be used within `Iteraptor`.

  **Experimental.** By implementing this behaviour one might how nested objects are serialized.

  All the implementations should be named as `Module.concat("Iteraptable", TargetModule)`.
  """

  @callback dump(any()) :: map()
  @callback summon(binary()) :: any()

  @delimiter if Version.compare(System.version(), "1.8.0") == :lt, do: "_", else: "·"
  @prefix if(Version.compare(System.version(), "1.8.0") == :lt, do: "struct", else: "s") <>
            @delimiter
  @doc false
  def prefix, do: @prefix
end

defmodule Iteraptable.Time do
  @moduledoc false

  @behaviour Iteraptable

  @name Iteraptable.prefix() <> "time"

  @impl Iteraptable
  def dump(%Time{} = time), do: %{@name => Time.to_iso8601(time)}
  @impl Iteraptable
  def summon(time), do: Time.from_iso8601!(time)
end

defmodule Iteraptable.Date do
  @moduledoc false

  @behaviour Iteraptable

  @name Iteraptable.prefix() <> "date"

  @impl Iteraptable
  def dump(%Date{} = date), do: %{@name => Date.to_iso8601(date)}
  @impl Iteraptable
  def summon(date), do: Date.from_iso8601!(date)
end
