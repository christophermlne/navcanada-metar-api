# TODO this way of defining a supervisor is deprecated in Elixir 1.6
defmodule MetarService.Supervisor do
  use Supervisor

  alias MetarService.{Coordinator,Store}

  def start_link, do:
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])

  def init(_) do
    children = [
      worker(Coordinator, [], restart: :temporary),
      worker(Store, [], restart: :temporary)
    ]
    supervise(children, [strategy: :one_for_all])
  end
end
