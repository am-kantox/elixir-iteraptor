defmodule Struct1 do
  @moduledoc false
  @fields [field1: nil]

  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end

defmodule Struct2 do
  @moduledoc false
  @fields [field2: nil]

  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end

defmodule Iteraptor.Struct do
  @moduledoc false

  @fields [field: nil]

  @doc false
  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end
