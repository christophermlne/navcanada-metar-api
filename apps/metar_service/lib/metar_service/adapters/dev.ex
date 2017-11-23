defmodule MetarService.Adapters.Dev do

  def get(station, :metar), do: get("./sample_data/metar.xml")
  def get(station, :taf),   do: get("./sample_data/taf.xml")

  defp get(path) do
    {:ok, file} = Path.expand(path) |> Path.absname|> File.open([:read])
    IO.read(file, :all)
  end
end
