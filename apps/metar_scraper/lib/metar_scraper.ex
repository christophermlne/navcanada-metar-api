defmodule MetarScraper do
  alias MetarScraper.Server

  defdelegate get(pid, station), to: Server

  def pid, do: Server
end
