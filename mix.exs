defmodule Periscope.MixProject do
  use Mix.Project

  def project do
    [
      app: :periscope,
      version: "0.3.4",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev}
    ]
  end

  defp description do
    """
    Tools for analyzing liveviews. Displays the currently-loaded liveview, the socket, the assigns, etc.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["C. Beers"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/caleb-bb/periscope",
        "Docs" => "https://hexdocs.pm/periscope"
      }
    ]
  end
end
