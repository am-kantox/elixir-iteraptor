defmodule Property.Iteraptor.Test do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import StreamData

  defmacrop aib, do: quote do: one_of([atom(:alphanumeric), integer(), binary()])

  defmacrop leaf_list, do: quote do: list_of(aib())
  defmacrop leaf_map, do: quote do: map_of(aib(), aib())
  defmacrop leaf_keyword, do: quote do: keyword_of(aib())
  defmacrop leaf,
    do: quote do: one_of([leaf_list(), leaf_map(), leaf_keyword()])

  defmacrop non_leaf_list, do: quote do: list_of(leaf())
  defmacrop non_leaf_map, do: quote do: map_of(aib(), leaf())
  defmacrop non_leaf_keyword, do: quote do: keyword_of(leaf())
  defmacrop non_leaf,
    do: quote do: one_of([non_leaf_list(), non_leaf_map(), non_leaf_keyword()])

  defmacrop maybe_leaf_list,
    do: quote do: list_of(one_of([leaf(), non_leaf()]))
  defmacrop maybe_leaf_map,
    do: quote do: map_of(aib(), one_of([leaf(), non_leaf()]))
  defmacrop maybe_leaf_keyword,
    do: quote do: keyword_of(one_of([leaf(), non_leaf()]))
  defmacrop maybe_leaf,
    do: quote do: one_of([maybe_leaf_list(), maybe_leaf_map(), maybe_leaf_keyword()])


  test "#each/3 returns itself" do
    check all term <- maybe_leaf(), max_runs: 25 do
      assert Iteraptor.each(term, &inspect/1) == term
    end
  end

  test "#map/3 sets all leaves" do
    check all term <- maybe_leaf(), max_runs: 25 do
      result =
        term
        |> Iteraptor.map(fn _ -> "." end)
        |> Iteraptor.to_flatmap()
        |> Map.values()
        |> Kernel.++(["."])
        |> Enum.uniq()

      assert result == ["."]
    end
  end

  test "#reduce/4 has same leaves as a mapper" do
    check all term <- maybe_leaf(), max_runs: 25 do
      reduced =
        Iteraptor.reduce(term, [], fn _, acc -> ["." | acc] end)
      mapped =
        term
        |> Iteraptor.map(fn _ -> "." end)
        |> Iteraptor.to_flatmap()
        |> Map.values()

      assert reduced == mapped
    end
  end

  test "#map_reduce/4 mimics 2 tests above :)" do
    check all term <- maybe_leaf(), max_runs: 25 do
      map_reducer = fn {k, _}, acc ->
        {{k, "."}, ["." | acc]}
      end
      {mapped, reduced} = Iteraptor.map_reduce(term, [], map_reducer)

      assert reduced == mapped |> Iteraptor.to_flatmap() |> Map.values()
    end
  end
end
