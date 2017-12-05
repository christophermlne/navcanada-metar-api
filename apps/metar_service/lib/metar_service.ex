defmodule MetarService do
  alias MetarService.{Server,Station}

  defdelegate get(station), to: Server

  def stations_within(station) do
    with {:ok, valid_station} <- Station.valid_id?(station),
         {:ok, nearby_stations} <- Server.stations_within(valid_station)
    do
      {:ok, nearby_stations}
    else
      {:error, _} -> {:ok, []}
    end
  end
end
