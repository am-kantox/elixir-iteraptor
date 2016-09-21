defmodule Iteraptor.IteraptableTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog
  doctest Iteraptor.Iteraptable


# defmodule Iteraptor.Struct do
#   @fields [field: nil]
#
#   def fields, do: @fields
#   defstruct @fields
#
#   use Iteraptor.Iteraptable
# end

  test "iterapted struct is enumerated" do
    assert capture_log(fn ->
      %Iteraptor.Struct{field: 42}
        |> Enum.each(fn e -> Logger.debug(inspect(e)) end)
    end) =~ "{:field, 42}"
  end
end
