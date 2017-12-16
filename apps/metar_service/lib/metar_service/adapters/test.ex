defmodule MetarService.Adapters.Test do
  def get(station, :metar), do: get("./sample_data/metar.xml")
  def get(station, :taf),   do: get("./sample_data/taf.xml")

  defp get(path) do
    case Path.expand(path) |> Path.absname|> File.open([:read]) do
      {:ok, file} -> {:ok, IO.read(file, :all)}
      {:error, msg} -> {:error, msg}
    end
  end
end
