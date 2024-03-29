defmodule MetarService.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:scraper_worker_pool, poolboy_config()),
      worker(MetarService.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: MetarService.AppSupervisor]
    Supervisor.start_link(children, opts)
  end

  # TODO max restarts with exponential falloff
  defp poolboy_config do
    [{:name, {:local, :scraper_worker_pool}},
     {:worker_module, MetarService.Worker},
     {:size, 2},
     {:max_overflow, 1}]
  end
end
