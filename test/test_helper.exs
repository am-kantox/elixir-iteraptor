ExUnit.start()

defmodule Struct1 do
  @fields [field1: nil]

  def fields, do: @fields
  defstruct @fields
end

defmodule Struct2 do
  @fields [field2: nil]

  def fields, do: @fields
  defstruct @fields
end
