defmodule Iteraptor.Config do
  @moduledoc ~S"""
    Extra functions to deal with runtime configuration.
  """

  @doc """
  Reads the application config and recursively changes all the `{:key, "VAR"}`
    tuples with runtime system environment read from "VAR".

  Default value for `:key` is `:system`, but it might be adjusted to avoid
    clashes with other libraries implementing `{:system, "FOO"}` functionality,
    like Phoenix and/or Ecto.

  ## Examples:

      iex> System.put_env("FOO", "42")
      iex> Application.put_env(
      ...>   :iteraptor,
      ...>   :key,
      ...>   [value: [value: {:my_system, "FOO"}]],
      ...>   persistent: true
      ...> )
      iex> Application.get_all_env(:iteraptor)
      [key: [value: [value: {:my_system, "FOO"}]]]
      iex> Iteraptor.Config.from_env(:iteraptor, &String.to_integer/1, :my_system)
      iex> Application.get_all_env(:iteraptor)
      [key: [value: [value: 42]]]
  """
  @spec from_env(app :: atom(), converter :: (binary() -> any()), key :: atom()) :: :ok
  def from_env(app, converter \\ & &1, key \\ :system) when is_function(converter, 1) do
    app
    |> Application.get_all_env()
    |> Iteraptor.map(fn
      {_, {^key, v}} -> v |> System.get_env() |> converter.()
      {_, v} -> v
    end)
    |> Enum.each(fn {key, value} ->
      Application.put_env(app, key, value, persistent: true)
    end)
  end
end
