defmodule MetarService.Adapters.Test do
  def get(_station, :metar), do: get("./sample_data/metar_test.xml")
  def get(_station, :taf),   do: get("./sample_data/taf_test.xml")

  defp get(path) do
    case Path.expand(path) |> Path.absname|> File.open([:read]) do
      {:ok, file} -> {:ok, IO.read(file, :all)}
      {:error, msg} -> {:error, msg}
    end
  end
end
