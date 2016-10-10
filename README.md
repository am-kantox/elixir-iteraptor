# Iteraptor

[![Build Status](https://travis-ci.org/am-kantox/elixir-iteraptor.svg?branch=master)](https://travis-ci.org/am-kantox/elixir-iteraptor)
[![Inline docs](http://inch-ci.org/github/am-kantox/elixir-iteraptor.svg)](http://inch-ci.org/github/am-kantox/elixir-iteraptor)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/am-kantox/elixir-iteraptor.svg)](https://beta.hexfaktor.org/github/am-kantox/elixir-iteraptor)
[![Hex.pm](https://img.shields.io/badge/hex-v.0.5.1-blue.svg?style=flat)](https://hex.pm/packages/iteraptor)

### Handy enumerable operations

  * `Iteraptor.to_flatmap/1` to flatten a deeply nested map/list/keyword/struct into flatten map with concatenated keys;
  * `Iteraptor.from_flatmap/1` to “unveil”/“unflatten” the previously flattened map into nested structure;
  * `Iteraptor.each/2` to iterate over nested a deeply nested map/list/keyword/struct;
  * `use Iteraptor.Iteraptable` to automagically implement `Enumerable` and `Collectable` protocols on the structure.

### HexDocs

  * [API Reference](https://hexdocs.pm/iteraptor/api-reference.html)
  * [`Iteraptor`](https://hexdocs.pm/iteraptor/Iteraptor.html)
  * [`Iteraptor.Iteraptable`](https://hexdocs.pm/iteraptor/Iteraptor.Iteraptable.html)

### Installation

  1. Add `iteraptor` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:iteraptor, "~> 0.6.0"}]
    end
    ```

  2. Ensure `iteraptor` is started before your application:

    ```elixir
    def application do
      [applications: [:iteraptor]]
    end
    ```

### Usage

```elixir
iex> %{a: %{b: %{c: 42, d: [nil, 42]}, e: [:f, 42]}} |> Iteraptor.to_flatmap
%{"a.b.c" => 42, "a.b.d.0" => nil, "a.b.d.1" => 42, "a.e.0" => :f, "a.e.1" => 42}
```

To be implicitly as explicit as possible, the current implementation creates
string keys for those, containing joiner and atoms for those that haven’t.

That makes normal maps to be resistant to

```elixir
iex> %{a: %{b: %{c: 42}}} |> Iteraptor.to_flatmap |> Iteraptor.from_flatmap
%{a: %{b: %{c: 42}}}

```

### Changelog

#### `0.5.0`

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

Support for [structs](http://elixir-lang.org/getting-started/structs.html) on input.
Structs will be automagically created on `|> Iteraptor.from_flatmap` from
keys like `StructName%field` if a) this structure is known to the system
and b) keys are consistent (e. g. there are no subsequent elements,
belonging to different structs: `["S1%f" => 42, "S2%f" => 3.14]`.)

Please see examples for an inspiration.

#### `0.3.0`

Support for [`Keyword`](http://elixir-lang.org/docs/stable/elixir/Keyword.html) on input,
but it will be output as map for `|> Iteraptor.to_flatmap |> Iteraptor.from_flatmap`
back and forth transformation.
