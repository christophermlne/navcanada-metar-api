defmodule MetarService.Server do
  alias MetarService.{Station,Store}

  def get(station) do
    with {:ok, valid_station} <- Station.valid_id?(station),
         {:ok, metar} <- Store.find(:metar, valid_station),
         {:ok, taf}   <- Store.find(:taf, valid_station),
         {:ok, nearby_stations} <- Station.within_radius(valid_station, 100.0)
    do
      {:ok, %{
        metar: metar,
        taf: taf,
        retrieved_at: timestamp(),
        nearby_stations: nearby_stations
       }}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
