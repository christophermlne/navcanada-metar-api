defmodule MetarService.Station do
  alias MetarService.Region

  @enforce_keys [:station, :reports]
  defstruct station: nil, reports: nil, longitude: nil, latitude: nil, flight_category: nil, latest_observation_time: nil, sea_level_pressure_mb: nil, elevation_m: nil

  def valid_id(station) do
    case Region.all() |> Enum.find(&(station == &1)) do
      nil -> {:error, "Not a valid station id."}
      station -> {:ok, station}
    end
  end
end
