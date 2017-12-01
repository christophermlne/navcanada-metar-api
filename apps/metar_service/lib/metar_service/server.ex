defmodule MetarService.Server do
  alias MetarService.{Station,Store}

  def get(station) do
    with {:ok, valid_station} <- Station.valid_id?(station),
         {:ok, metar} <- Store.find(:metar, valid_station),
         {:ok, taf}   <- Store.find(:taf, valid_station)
    do
      #TODO fix timestamp
      {:ok, %{data: %{metar: metar, taf: taf},
          retrieved_at: timestamp()}}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
