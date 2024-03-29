defmodule MetarService.Mixfile do
  use Mix.Project

  def project do
    [
      app: :metar_service,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :poolboy, :httpoison],
      mod: {MetarService.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:poolboy, "~> 1.5"},
      {:httpoison, "~> 0.13"},
      {:sweet_xml, "~> 0.6.5"},
      {:csv, "~> 2.1"},
      {:math, "~> 0.3.0"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    # do not start the supervision tree in test environment
    [
      test: "test --no-start"
    ]
  end
end
