defmodule MetarService.Adapters.Dev do
  def get(station) do
    {:ok, file} = Path.expand('./sample_data.xml') |> Path.absname|> File.open([:read])

    IO.read(file, :all)


    # case HTTPoison.get(url(station)) do
    #   {:ok, %{ status_code: 200, body: body}} ->
    #     Path.expand('./sample_data.xml') |> Path.absname |> File.write(body, [:write])
    #     body
    #   {:error, %{ reason: reason }} ->
    #     {:error, reason}
    #   _ -> {:error, "Unknown error"}
    # end
  end

  def url(station), do:
    "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=#{station}&hoursBeforeNow=4"
end
