defmodule MetarService.Adapters.Dev do
  def get(station) do
    {:ok, file} = Path.expand("./sample_data.xml") |> Path.absname|> File.open([:read])

    IO.read(file, :all)
  end
end
