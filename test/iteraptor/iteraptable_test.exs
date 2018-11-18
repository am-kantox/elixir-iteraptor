defmodule Iteraptor.Iteraptable.Test do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog
  doctest Iteraptor.Iteraptable

  test "iterapted struct is flattened" do
    assert capture_log(fn ->
             %{m: %{field: 42}, s: %Iteraptor.Struct{field: 42}, dt: [~D[2018-11-18], ~T[13:00:07]]}
             |> Iteraptor.to_flatmap()
             |> inspect()
             |> Logger.debug()
           end) =~ ~r|"dt.0.struct_date" => "2018-11-18", "dt.1.struct_time" => "13:00:07"|
           # end) =~ ~r|"dt.0.s·date" => "2018-11-18", "dt.1.s·time" => "13:00:07"|
        end

  test "iterapted struct is enumerated" do
    assert capture_log(fn ->
             %Iteraptor.Struct{field: 42}
             |> Enum.each(fn e -> Logger.debug(inspect(e)) end)
           end) =~ "{:field, 42}"
  end

  test "iterapted struct is collected" do
    assert Enum.into([field: 42], %Iteraptor.Struct{}) == %Iteraptor.Struct{field: 42}
  end

  test "iterapted struct is accessed" do
    assert %Iteraptor.Struct{field: 42}[:field] == 42
  end

  test "iterapted struct with derived Derivable" do
    ds = %Iteraptor.DerivedStruct{field: 42}
    assert Derivable.ok(ds) == {:ok, ds, %{ds | field: nil}}
  end

  test "prevents inclusion into non-structs" do
    assert_raise UndefinedFunctionError,
                 ~r|function Bad.__struct__/0 is undefined|,
                 fn ->
                   Module.create(
                     Bad,
                     quote(do: use(Iteraptor.Iteraptable)),
                     Macro.Env.location(__ENV__)
                   )
                 end
  end
end
