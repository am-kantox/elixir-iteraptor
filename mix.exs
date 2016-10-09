defmodule Iteraptor.Mixfile do
  use Mix.Project

  def project do
    [app: :iteraptor,
     version: File.read!(Path.join("config", "VERSION")),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_ncurses, git: "https://github.com/jfreeze/ex_ncurses.git", only: :dev},
      {:issuer, "~> 0.0", only: :dev},

      {:credo, "~> 0.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp description do
    """
    This small library allows the deep iteration / mapping of Enumerables.
    """
  end

  defp package do
    [# These are the default files included in the package
     name: :iteraptor,
     files: ["lib", "config", "mix.exs", "README*"],
     maintainers: ["Aleksei Matiushkin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mudasobwa/iteraptor",
              "Docs" => "http://mudasobwa.github.io/iteraptor/"}]
  end
end
