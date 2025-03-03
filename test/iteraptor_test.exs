defmodule Iteraptor.Test do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureLog
  doctest Iteraptor

  @empty [map: %{}, list: []]
  @list [:a1, %{a2: 42, a3: 3.1415, a4: [:a5, true], a6: %{a7: 42}}, ~w|a8 a9|a, :a10]
  # @map %{a1: 42, a2: %{ a3: 42, a4: %{ a5: 42, a6: ~w|a7 a8|a}}}
  @keyword [a1: 42, a2: %{a3: 42, a4: %{a5: 42, a6: [a7: 42, a7: 3.14, a8: 42]}}]
  @nest %{top: %{key: 42, subkey: %{key: 3.1415}}, keys: ~w|1 2 3|}

  test "handles empty input properly" do
    ~w|map list|a
    |> Enum.each(fn key ->
      # assert Iteraptor.each(@empty[key], & &1) == @empty[key]
      assert capture_log(fn ->
               @empty[key] |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
             end) == ""
    end)
  end

  test "map / each prints out the iterated values" do
    result =
      capture_log(fn ->
        @nest |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
      end)

    assert result =~ "{[:keys, 0], \"1\"}"
    assert result =~ "{[:keys, 1], \"2\"}"
    assert result =~ "{[:keys, 2], \"3\"}"
    assert result =~ "{[:top, :key], 42}"
    assert result =~ "{[:top, :subkey, :key], 3.1415}"
  end

  test "map[:full_parent] / each prints out the iterated values" do
    result =
      capture_log(fn ->
        @nest |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
      end)

    assert result =~ "[:keys, 0], \"1\"}"
    assert result =~ "[:keys, 1], \"2\"}"
    assert result =~ "[:keys, 2], \"3\"}"
    assert result =~ "[:top, :key], 42}"
    assert result =~ "[:top, :subkey, :key], 3.1415}"
  end

  test "list / each prints out the iterated values" do
    result =
      capture_log(fn ->
        @list |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
      end)

    assert result =~ "{[0], :a1}"
    assert result =~ "{[1, :a2], 42}"
    assert result =~ "{[1, :a3], 3.1415}"
    assert result =~ "{[1, :a4, 0], :a5}"
    assert result =~ "{[1, :a4, 1], true}"
    assert result =~ "{[1, :a6, :a7], 42}"
    assert result =~ "{[2, 0], :a8}"
    assert result =~ "{[2, 1], :a9}"
    assert result =~ "{[3], :a10}"
  end

  test "keyword / each prints out the iterated values" do
    result =
      capture_log(fn ->
        @keyword |> Iteraptor.each(fn {k, v} -> Logger.debug(inspect({k, v})) end)
      end)

    assert result =~ "{[:a1], 42}"
    assert result =~ "{[:a2, :a3], 42}"
    assert result =~ "{[:a2, :a4, :a5], 42}"
    assert result =~ "{[:a2, :a4, :a6, :a7], 42}"
    assert result =~ "{[:a2, :a4, :a6, :a7], 3.14}"
    assert result =~ "{[:a2, :a4, :a6, :a8], 42}"
  end

  test "keyword / each prints keys in the reversed order" do
    result =
      capture_log(fn ->
        @keyword |> Iteraptor.map(fn {k, v} -> Logger.debug(inspect({k, v})) end, keys: :reverse)
      end)

    assert result =~ "{[:a1], 42}"
    assert result =~ "{[:a3, :a2], 42}"
    assert result =~ "{[:a5, :a4, :a2], 42}"
    assert result =~ "{[:a7, :a6, :a4, :a2], 42}"
    assert result =~ "{[:a7, :a6, :a4, :a2], 3.14}"
    assert result =~ "{[:a8, :a6, :a4, :a2], 42}"
  end

  test "Iteraptor.jsonify/2 works" do
    result = Iteraptor.jsonify(@keyword)

    assert result == %{
             "a1" => 42,
             "a2" => %{
               "a3" => 42,
               "a4" => %{"a5" => 42, "a6" => %{"a7" => 3.14, "a8" => 42}}
             }
           }
  end

  test "Iteraptor.jsonify/2 works for values as well" do
    result = Iteraptor.jsonify([foo: :bar, baz: [:zzz, 42]], values: true)

    assert result == %{
             "foo" => "bar",
             "baz" => ["zzz", 42]
           }
  end

  test "Iteraptor.jsonify/2 works for keys: false as well" do
    result = Iteraptor.jsonify([foo: :bar, baz: [:zzz, 42]], keys: false)

    assert result == %{
             foo: :bar,
             baz: [:zzz, 42]
           }
  end

  test "map[:full_parent] / each returns the original map" do
    Enum.each([{@nest, :tuple}, {@list, nil}], fn {input, full_parent} ->
      assert(input == Iteraptor.each(input, fn _ -> :ok end, full_parent: full_parent))
    end)
  end

  test "handles nested structs properly" do
    result =
      capture_log(fn ->
        Iteraptor.each(
          %{ok: 42, nested: %Iteraptor.BareStruct{}},
          &Logger.debug(inspect(&1))
        )
      end)

    assert result =~ "{[:nested, :bar], :baz}"
    assert result =~ "{[:nested, :foo], 42}"
    assert result =~ "{[:ok], 42}"
  end

  test "handles nested structs properly with [structs: :values]" do
    result =
      capture_log(fn ->
        Iteraptor.each(
          %{ok: 42, nested: %Iteraptor.BareStruct{}},
          &Logger.debug(inspect(&1)),
          structs: :values
        )
      end)

    assert result =~ "{[:nested], %Iteraptor.BareStruct{foo: 42, bar: :baz}}"
    assert result =~ "{[:ok], 42}"
  end

  test "handles nested structs properly with [structs: :keep]" do
    result =
      Iteraptor.map(
        %{ok: 42, nested: %Iteraptor.BareStruct{}},
        & &1,
        structs: :keep,
        yield: :all
      )

    assert %Iteraptor.BareStruct{} = result[:nested]
  end
end
