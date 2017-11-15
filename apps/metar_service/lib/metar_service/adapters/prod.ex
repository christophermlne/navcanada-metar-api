defmodule MetarService.Adapters.Prod do
  def get(station) do
    case HTTPoison.get(url(station)) do
      {:ok, %{ status_code: 200, body: body}} ->
        body
      {:error, %{ reason: reason }} ->
        {:error, reason}
      _ -> {:error, "Unknown error"}
    end
  end

  def url(station), do:
    "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=#{station}&hoursBeforeNow=4"
end
