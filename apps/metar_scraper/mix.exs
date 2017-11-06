defmodule MetarScraper.Mixfile do
  use Mix.Project

  def project do
    [
      app: :metar_scraper,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :poolboy],
      mod: {MetarScraper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hound, "~> 1.0"},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:poolboy, "~> 1.5"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
