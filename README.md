# Iteraptor

[![Build Status](https://travis-ci.org/am-kantox/elixir-iteraptor.svg?branch=master)](https://travis-ci.org/am-kantox/elixir-iteraptor)
[![Inline docs](http://inch-ci.org/github/am-kantox/elixir-iteraptor.svg)](http://inch-ci.org/github/am-kantox/elixir-iteraptor)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/am-kantox/elixir-iteraptor.svg)](https://beta.hexfaktor.org/github/am-kantox/elixir-iteraptor)

Handy enumerable operations:

  * `to_flatmap`

## Installation

  1. Add `iteraptor` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:iteraptor, "~> 0.3.0"}]
    end
    ```

  2. Ensure `iteraptor` is started before your application:

    ```elixir
    def application do
      [applications: [:iteraptor]]
    end
    ```
## Usage

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

As of version `0.3.0`, the module supports
[`Keyword`](http://elixir-lang.org/docs/stable/elixir/Keyword.html) on input,
but it will be output as map for `|> Iteraptor.to_flatmap |> Iteraptor.from_flatmap`
back and forth transformation.
