defmodule MetarScraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp poolboy_config do
    [{:name, {:local, :scraper_worker_pool}},
     {:worker_module, MetarScraper.Worker},
     {:size, 1},
     {:max_overflow, 1}]
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:scraper_worker_pool, poolboy_config()),
      worker(MetarScraper.Server, []),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MetarScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
