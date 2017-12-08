defmodule Api.PageController do
  use Api.Web, :controller

  def index(conn, %{ "station" => station_id }) do
    case MetarService.get(station_id) do
      {:ok,
        %{taf: taf,
          metar: %{reports: reports},
          retrieved_at: retrieved_at,
          nearby_stations: nearby_stations
        }
      } ->
        render conn, "index.html", station_id: station_id, report: reports, taf: taf, error: nil, retrieved_at: retrieved_at, nearby_stations: nearby_stations
      {:error, msg} ->
        render conn, "index.html", station_id: station_id, report: %{ history: [], currrent: ""}, taf: "", error: msg, retrieved_at: nil, nearby_stations: []
    end
  end

  def index(conn, _params), do:
    render conn, "index.html", station_id: "", report: %{ history: [], current: ""}, taf: "", error: nil, retrieved_at: nil, nearby_stations: []
end
