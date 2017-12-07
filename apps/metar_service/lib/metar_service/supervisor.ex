defmodule MetarService.Supervisor do
  use Supervisor

  alias MetarService.{Coordinator,Store}

  def start_link, do:
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])

  def init(_) do
    children = [
      worker(Coordinator, []),
      worker(Store, [])
    ]
    supervise(children, [strategy: :one_for_all])
  end
end
