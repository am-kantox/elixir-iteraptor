defmodule Iteraptor.Mixfile do
  use Mix.Project

  @app :iteraptor

  def project do
    [
      app: @app,
      version: "0.8.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger]
    ]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, "~> 0.0", only: :docs}
    ]
  end

  defp description do
    """
    This small library allows the deep iteration / mapping of Enumerables.
    """
  end

  defp package do
    [# These are the default files included in the package
     name: @app,
     files: ["lib", "config", "mix.exs", "README*"],
     maintainers: ["Aleksei Matiushkin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/am-kantox/elixir-iteraptor",
              "Docs" => "http://hexdocs.pm/iteraptor"}]
  end
end
