defmodule MetarService.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:scraper_worker_pool, poolboy_config()),
      worker(MetarService.Store, []),
      worker(MetarService.Coordinator, []),
    ]

    opts = [strategy: :one_for_one, name: MetarService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp poolboy_config do
    [{:name, {:local, :scraper_worker_pool}},
     {:worker_module, MetarService.Worker},
     {:size, 5},
     {:max_overflow, 2}]
  end
end
