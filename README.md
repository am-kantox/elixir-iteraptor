# Iteraptor

[![Build Status](https://travis-ci.org/am-kantox/elixir-iteraptor.svg?branch=master)](https://travis-ci.org/am-kantox/elixir-iteraptor)
[![Inline docs](http://inch-ci.org/github/am-kantox/elixir-iteraptor.svg)](http://inch-ci.org/github/am-kantox/elixir-iteraptor)
[![Hex.pm](https://img.shields.io/badge/hex-v.1.12.0-blue.svg?style=flat)](https://hex.pm/packages/iteraptor)

### Handy enumerable operations

  * [`Iteraptor.each/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#each/3)
    to iterate a deeply nested map/list/keyword;
  * [`Iteraptor.map/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#map/3)
    to map a deeply nested map/list/keyword;
  * [`Iteraptor.reduce/4`](https://hexdocs.pm/iteraptor/Iteraptor.html#reduce/4)
    to reduce a deeply nested map/list/keyword;
  * [`Iteraptor.map_reduce/4`](https://hexdocs.pm/iteraptor/Iteraptor.html#map_reduce/4)
    to map and reduce a deeply nested map/list/keyword;
  * [`Iteraptor.filter/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#filter/3)
    to filter a deeply nested map/list/keyword;
  * [`Iteraptor.to_flatmap/2`](https://hexdocs.pm/iteraptor/Iteraptor.html#to_flatmap/2)
    to flatten a deeply nested map/list/keyword into
    flatten map with concatenated keys;
  * [`Iteraptor.from_flatmap/3`](https://hexdocs.pm/iteraptor/Iteraptor.html#from_flatmap/3)
    to “unveil”/“unflatten” the previously flattened map into nested structure;
  * [`use Iteraptor.Iteraptable`](https://hexdocs.pm/iteraptor/Iteraptor.Iteraptable.html)
    to automagically implement `Enumerable` and `Collectable` protocols, as well as
    `Access` behaviour on the structure.

**bonus:**

  * [`Iteraptor.jsonify/2`](https://hexdocs.pm/iteraptor/Iteraptor.html#jsonify/2) to prepare the term for JSON interchange; it basically converts keys to strings and keywords to maps because JSON encoders might have issues with serializing keywords.

  * [`Iteraptor.Extras.bury/4`](https://hexdocs.pm/iteraptor/Iteraptor.Extras.html#bury/4)
    to store the value deeply inside nested term (the intermediate keys are created as
    necessary.)

### HexDocs

  * [API Reference](https://hexdocs.pm/iteraptor/api-reference.html)
  * [`Iteraptor`](https://hexdocs.pm/iteraptor/Iteraptor.html)
  * [`Iteraptor.Iteraptable`](https://hexdocs.pm/iteraptor/Iteraptor.Iteraptable.html)

### Usage

#### Iterating, Mapping, Reducing

```elixir
# each
iex> %{a: %{b: %{c: 42}}} |> Iteraptor.each(&IO.inspect/1, yield: :all)
# {[:a], %{b: %{c: 42}}}
# {[:a, :b], %{c: 42}}
# {[:a, :b, :c], 42}
%{a: %{b: %{c: 42}}}

# map
iex> %{a: %{b: %{c: 42}}} |> Iteraptor.map(fn {k, _} -> Enum.join(k) end)
%{a: %{b: %{c: "abc"}}}

iex> %{a: %{b: %{c: 42}}}
...> |> Iteraptor.map(fn
...>      {[_], _} = self -> self
...>      {[_, _], _} -> "YAY"
...>    end, yield: :all)
%{a: %{b: "YAY"}}

# reduce
iex> %{a: %{b: %{c: 42}}}
...> |> Iteraptor.reduce([], fn {k, _}, acc ->
...>      [Enum.join(k, "_") | acc]
...>    end, yield: :all)
...> |> :lists.reverse()
["a", "a_b", "a_b_c"]

# map-reduce
iex> %{a: %{b: %{c: 42}}}
...> |> Iteraptor.map_reduce([], fn
...>      {k, %{} = v}, acc -> {{k, v}, [Enum.join(k, ".") | acc]}
...>      {k, v}, acc -> {{k, v * 2}, [Enum.join(k, ".") <> "=" | acc]}
...>    end, yield: :all)
{%{a: %{b: %{c: 42}}}, ["a.b.c=", "a.b", "a"]}

# filter
iex> %{a: %{b: 42, e: %{f: 3.14, c: 42}, d: %{c: 42}}, c: 42, d: 3.14}
...> |> Iteraptor.filter(fn {key, _} -> :c in key end, yield: :none)
%{a: %{e: %{c: 42}, d: %{c: 42}}, c: 42}
```

#### Flattening

```elixir
iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}
...> |> Iteraptor.to_flatmap(delimiter: "_")
#⇒ %{"a_b_c" => 42, "a_b_d_0" => nil, "a_b_d_1" => 42, "a_e_0" => :f, "a_e_1" => 42}

iex> %{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
...> |> Iteraptor.from_flatmap
#⇒ %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}}
```

#### Extras

```elixir
iex> Iteraptor.jsonify([foo: [bar: [baz: :zoo], boo: 42]], values: true)
%{"foo" => %{"bar" => %{"baz" => "zoo"}, "boo" => 42}}

iex> Iteraptor.Extras.bury([foo: :bar], ~w|a b c d|a, 42)
[a: [b: [c: [d: 42]]], foo: :bar]
```

**As of version `1.2.0` there is an experimental AST traversal feature:**

```elixir
iex> Iteraptor.AST.reduce((quote do: 42), [], fn e, acc -> [e | acc], yield: :all)
'*'
```

---

### Installation

Add `iteraptor` to your list of dependencies in `mix.exs`:

```elixir
def deps, do: [{:iteraptor, "~> 1.5"}]
```


### Changelog

#### `1.14.0`

Updated dependecies to modern _Elixir_

#### `1.13.0`

`keys: :reverse` configuration option in all traversion functions to simplify pattern matching on leaf keys

#### `1.10.0`

`Iteraptor.jsonify/2` for deep conversion of keyword lists to maps.

#### `1.8.0`

`Iteraptor.Config` for deep substitution of `{:system, "VAR"}` tuples with the
  values taken from the system environment in runtime.

#### `1.7.0`

`Iteraptor.Array` with `Access` support. Basically, `Array` is the list with `Access` support.

- `1.7.2` → fixed bug with type recognition for `MapSet` and `Iteraptor.Array`.

#### `1.6.0`

`Iteraptor.jsonify/2`.

#### `1.5.0`

All iterators do now accept `structs: :values` keyword argument to prevent nested iteration into structs.

Experimental support for `Iteraptable` protocol.

#### `1.4.0`

Extended support for `Iteraptor.Iteraptable`:

#### `1.3.0`

We now support `MapSet`s.

#### `1.0.0-rc1`

Better documentation, `Iteraptor.Extras.bury/3`.

#### `0.9.0`

Complete refactoring, `Iteraptor.map/3`, `Iteraptor.reduce/4`, `Iteraptor.map_reduce/4`.

#### `0.5.0`

**NB:** This functionality is experimental and might not appear in `1.0.0` release.

`use Iteraptor.Iteraptable` inside structs to make them both
[`Enumerable`](http://elixir-lang.org/docs/stable/elixir/Enumerable.html) and
[`Collectable`](http://elixir-lang.org/docs/stable/elixir/Collectable.html):

```elixir
defmodule Iteraptor.Struct do
  @fields [field: nil]

  def fields, do: @fields
  defstruct @fields

  use Iteraptor.Iteraptable
end

iex> %Iteraptor.Struct{field: 42}
...>   |> Enum.each(fn e -> IO.inspect(e) end)
#⇒   {:field, 42}
```

#### `0.4.0`

_Experimental:_ support for [structs](http://elixir-lang.org/getting-started/structs.html) on input.
Structs will be automagically created on `|> Iteraptor.from_flatmap` from
keys like `StructName%field` if a) this structure is known to the system
and b) keys are consistent (e. g. there are no subsequent elements,
belonging to different structs: `["S1%f" => 42, "S2%f" => 3.14]`.)

#### `0.3.0`

Support for [`Keyword`](http://elixir-lang.org/docs/stable/elixir/Keyword.html) on input,
but it will be output as map for `|> Iteraptor.to_flatmap |> Iteraptor.from_flatmap`
back and forth transformation.
