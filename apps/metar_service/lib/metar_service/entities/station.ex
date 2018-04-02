defmodule MetarService.Station do
  alias MetarService.{Region,Store}

  @enforce_keys [:station]
  defstruct station: nil, name: nil, reports: nil, longitude: nil, latitude: nil, flight_category: nil, latest_observation_time: nil, sea_level_pressure_mb: nil, elevation_m: nil

  def names() do
    "apps/metar_service/data/stations/master.csv"
    |> Path.expand
    |> File.stream!
    |> CSV.decode(strip_fields: true)
    |> Enum.map(fn ({:ok, n}) -> n end)
    # TODO enum into
  end

  def valid_id?(station) do
    case Region.all() |> Enum.find(&(station == &1)) do
      nil -> {:error, "Not a valid station id."}
      station -> {:ok, station}
    end
  end

  def within_radius(station_id, distance_km \\ 20.0) do
    case Region.all() |> Enum.filter(&distance_in_km_between_stations(&1, station_id) <= distance_km) do
      :error -> {:ok, []}
      nearby_stations -> {:ok, nearby_stations}
    end
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
    case Store.find(:station, station_id) do
      {:ok, station} ->
        {:ok, {station.latitude, station.latitude}}
      {:error, _} -> {:error, "Coordinates unavailable for station"}
    end
  end
end
