require IEx;

defmodule MetarService.Server do
  alias MetarService.{Station,Store}

  def get(station) do
    with {:ok, valid_station} <- Station.valid_id?(station),
         {:ok, station} <- Store.find(:station, valid_station),
         {:ok, metar} <- Store.find(:metar, valid_station),
         {:ok, taf}   <- Store.find(:taf, valid_station),
         {:ok, nearby_stations} <- get_nearby_stations(valid_station, 200.0)
    do
      {:ok, %{
        station: station,
        metar: metar,
        taf: taf,
        retrieved_at: timestamp(),
        nearby_stations: nearby_stations
       }}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def search(query) do
    # TODO build out search functionality
    # query = query |> tokenize
    # if any token could be a full or partial match for an icao then search for that first
    # if no results from above or else search names for each token
    Store.all(:station)
    |> Enum.filter(fn ({icao_code, _station}) ->
         regex = ~r"#{query}"i
         String.match?(icao_code, regex)
       end)
    |> Enum.map(fn ({_, %{ code: code, name: name}}) -> %{ id: code, name: name } end)
  end

  # defp tokenize(query), do: String.split(query, " ")

  defp get_nearby_stations(station_id, radius) do
    {:ok, stations} = Station.within_radius(station_id, radius)
    {:ok, Enum.map(stations, fn (icao) ->
      Store.find(:station, icao)
      |> case do
        {:ok, data} -> data
      end
    end)}
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
