defmodule Api.PageController do
  use Api.Web, :controller

  def index(conn, %{ "station" => station_id }) do
    import MetarService

    with {:ok, %{data: %{taf: taf, metar: %{reports: reports}}, retrieved_at: retrieved_at} } <- get(station_id),
         {:ok, nearby_stations} <- stations_within(station_id)
    do
        render conn, "index.html", station_id: station_id, report: reports, taf: taf, error: nil, retrieved_at: retrieved_at, nearby_stations: nearby_stations
    else
      {:error, msg} ->
        render conn, "index.html", station_id: station_id, report: %{ history: [], currrent: ""}, taf: "", error: msg, retrieved_at: nil, nearby_stations: []
    end
  end

  def index(conn, _params), do:
    render conn, "index.html", station_id: "", report: %{ history: [], current: ""}, taf: "", error: nil, retrieved_at: nil, nearby_stations: []
end
