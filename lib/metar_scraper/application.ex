defmodule MetarScraper.Application do
  @moduledoc false

  use Application

  defp poolboy_config do
    [{:name, {:local, :scraper_worker_pool}},
     {:worker_module, MetarScraper.Worker},
     {:size, 5},
     {:max_overflow, 2}]
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:scraper_worker_pool, poolboy_config()),
      worker(MetarScraper.Server, []),
    ]

    opts = [strategy: :one_for_one, name: MetarScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
