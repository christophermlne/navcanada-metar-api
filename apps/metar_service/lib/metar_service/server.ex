# *TODO while we have a functioning nearby stations feature, perf went from sub-millisecond response
#    times to 10-20ms. This is because we must use the .get method on each station in Region.all() in order to get the Coords
#    to use in the radius filter
#      - prepopulate stations with coords
# * TODO a separate struct, 'Station', which contains the station-specific properties and
#     is keyed by station_id, will be used in the geo search
#       - implicit is the removal of the station properties from the metar data
#       - we will end up with 3 ets tables -> station_data, metar_data, taf_data
#       - we will end up with 3 structs -> Station, Metar, Taf
defmodule MetarService.Server do
  alias MetarService.{Station,Store,Region,Server}

  def get(station) do
    with {:ok, valid_station} <- Station.valid_id?(station),
         {:ok, metar} <- Store.find(:metar, valid_station),
         {:ok, taf}   <- Store.find(:taf, valid_station)
         # INFINITE RECURSION! {:ok, nearby_stations} <- stations_within(valid_station) #{:ok, ["CYXX", "CYVR", "CYYJ"]}
    do
      #TODO retrieved_at should be generated_at
      {:ok, %{data: %{metar: metar, taf: taf},
            retrieved_at: timestamp()
            # within_100_km: nearby_stations
             }
      }
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def stations_within(station_id, distance_km \\ 100.0) do
    nearby_stations = Region.stations_for(:pacific)
                      |> Enum.filter(&distance_in_km_between_stations(&1, station_id) <= distance_km)
    {:ok, nearby_stations}
  end

  defp distance_in_km_between_stations(station1, station2) do
    with {:ok, {lat1, lon1}} <- coords_for(station1),
         {:ok, {lat2, lon2}} <- coords_for(station2)
    do
      distance_in_km_between_earth_coordinates(lat1, lon1, lat2, lon2)
    else
      {:error, _} -> 99999
    end
  end

  defp distance_in_km_between_earth_coordinates(lat1, lon1, lat2, lon2) do
    # See SO answer here (written in JS): https://stackoverflow.com/a/365853/2802660
    import Math
    earth_radius_km = 6371

    dLat = deg2rad(lat2-lat1)
    dLon = deg2rad(lon2-lon1)

    lat1 = deg2rad(lat1)
    lat2 = deg2rad(lat2)

    a = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat1) * cos(lat2)
    c = 2 * atan2(sqrt(a), sqrt(1-a))

    earth_radius_km * c
  end

  defp coords_for(station_id) do
    # TODO can't include nearby stations with Server.get response due to infinite recursion
    # Station and Metar data need to be moved to separate ets tables
    case __MODULE__.get(station_id) do
      {:ok, %{data: %{metar: station}}} ->
        {:ok, {List.to_float(station.latitude), List.to_float(station.longitude)}}
      {:error, _} -> {:error, "Coordinates unavailable for station"}
    end
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
