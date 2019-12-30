defmodule Iteraptor.Mixfile do
  use Mix.Project

  @app :iteraptor
  @github "am-kantox/elixir-#{@app}"
  @version "1.10.1"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      xref: [exclude: []],
      dialyzer: [
        plt_file: {:no_warn, ".dialyzer/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer/ignore.exs"
      ]
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
      {:dialyxir, "~> 1.0.0-rc.6", only: [:ci, :dev], runtime: false},
      {:credo, "~> 1.0", only: [:ci, :dev, :test], runtime: false},
      {:stream_data, "~> 0.4", only: [:ci, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev},
      {:inch_ex, "~> 2.0", only: :docs}
    ]
  end

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": [
        "format --check-formatted",
        "credo --strict",
        "dialyzer --halt-exit-status"
      ]
    ]
  end

  defp description do
    """
    This small library allows the deep iteration / mapping of Enumerables.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: @app,
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/#{@github}",
        "Docs" => "http://hexdocs.pm/@{app}"
      }
    ]
  end

  defp docs do
    [
      main: "intro",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      logo: "stuff/images/logo.png",
      source_url: "https://github.com/#{@github}",
      extras: ["stuff/pages/intro.md"],
      groups_for_modules: [
        # Iteraptor

        Extras: [
          Iteraptor.Array,
          Iteraptor.Config,
          Iteraptor.Extras,
          Iteraptor.Iteraptable
        ],
        Experimental: [
          Iteraptor.AST
        ],
        Internals: [
          Iteraptor.Utils
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:ci), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
