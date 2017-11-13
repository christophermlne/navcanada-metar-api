defmodule MetarService.Station do
  @enforce_keys [:station, :reports]
  defstruct station: nil, reports: nil, longitude: nil, latitude: nil, flight_category: nil, latest_observation_time: nil, sea_level_pressure_mb: nil, elevation_m: nil
end
