defmodule MetarService do
  alias MetarService.Server

  defdelegate get(station), to: Server
end
