defmodule MetarService.Adapters.Prod do
  @base_url "https://aviationweather.gov/adds/dataserver_current/httpparam?requestType=retrieve&format=xml&"

  def get(stations, :metar), do: metar_url(stations) |> get
  def get(stations, :taf),   do: taf_url(stations)   |> get

  def get(url) do
    case HTTPoison.get(url) do
      {:ok, %{ status_code: 200, body: body}} ->
        {:ok, body}
      {:error, %{ reason: reason }} ->
        {:error, reason}
    end
  end

  defp metar_url(stations), do:
    @base_url <> "stationString=#{stations}&hoursBeforeNow=4&dataSource=metars"

  defp taf_url(stations), do:
    @base_url <> "stationString=#{stations}&hoursBeforeNow=1&timeType=valid&mostRecentForEachStation=constraint&dataSource=tafs"
end
