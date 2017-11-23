defmodule MetarService.Adapters.Dev do
  def get(station, :metar) do
      {:ok, file} = Path.expand("./sample_data.xml") |> Path.absname|> File.open([:read])

      IO.read(file, :all)
  end

  def get(station, :taf) do
      {:ok, file} = Path.expand("./sample_taf.xml") |> Path.absname|> File.open([:read])

      IO.read(file, :all)
  end
end
