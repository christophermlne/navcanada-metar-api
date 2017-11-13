defmodule MetarService do
  alias MetarService.Server

  defdelegate get(pid, station), to: Server

  def pid, do: Server
end
