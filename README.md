# Iteraptor

Handy enumerable operations:

  * `to_flatmap`

## Installation

  1. Add `iteraptor` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:iteraptor, "~> 0.1.0"}]
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
%{"a.b.c": 42, "a.b.d.0": nil, "a.b.d.1": 42, "a.e.0": :f, "a.e.1": 42}
```
