defmodule IteraptorTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog
  doctest Iteraptor

  test "each prints out the iterated values" do
    assert capture_log(fn ->
      %{a: %{b: %{c: 42}}} |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
    end) =~ "{:\"a.b.c\", 42}"
  end
end
