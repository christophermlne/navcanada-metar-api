defmodule Api.PageController do
  use Api.Web, :controller

  def index(conn, %{ "station" => station_id }) do
    import MetarService

    case get(pid(), station_id) do
      {:ok, %{ data: %{ reports: reports}, retrieved_at: retrieved_at }} ->
        render conn, "index.html", station_id: station_id, report: reports, error: nil, retrieved_at: retrieved_at
      {:error, msg} ->
        render conn, "index.html", station_id: station_id, report: %{ history: [], currrent: ""}, error: msg, retrieved_at: nil
    end
  end

  def index(conn, _params), do:
    render conn, "index.html", station_id: "", report: %{ history: [], current: ""}, error: nil, retrieved_at: nil
end
