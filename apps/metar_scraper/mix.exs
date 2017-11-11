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
      extra_applications: [:logger, :poolboy, :httpoison],
      mod: {MetarScraper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:poolboy, "~> 1.5"},
      {:httpoison, "~> 0.13"},
      {:sweet_xml, "~> 0.6.5"}
    ]
  end
end
