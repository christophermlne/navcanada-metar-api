defmodule Api.PageController do
  use Api.Web, :controller

  alias MetarScraper.Server

  def index(conn, %{ "station" => station_id }) do
    reports = case Server.get(Server, station_id) do
      %{ data: %{ reports: reports} } -> reports
      %{ data: nil } -> %{ current: "Error. Station does not exist or report not available.", history: []}
    end
    render conn, "index.html", station_id: station_id, report: reports
  end

  def index(conn, _params), do:
    render conn, "index.html", station_id: "", report: %{ history: [], current: ""}
end
