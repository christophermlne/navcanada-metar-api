defmodule MetarScraper.Worker do
  use GenServer
  alias MetarScraper.{Station,Region}

  ##############
  # Client API #
  ##############

  def start_link(opts \\ []), do:
    GenServer.start_link(__MODULE__, :ok, opts)

  def get_metars_for_station(pid, station), do:
    GenServer.call(pid, {:fetch_station, [station]})

  def get_metars_for_region(pid, region), do:
    GenServer.call(pid, {:fetch_region, region})

  def clear_cache(pid), do:
    GenServer.call(pid, {:clear_cache})

  def stop(pid), do:
    GenServer.cast(pid, :stop)

  ####################
  # Server Callbacks #
  ####################

  def init(:ok), do:
    {:ok, %{}}

  def handle_call({:clear_cache}, {_from, _ref}, _state), do:
    {:reply, :ok, %{}}

  def handle_call({:fetch_station, station}, {_from, _ref}, state), do:
    {:reply, metar_taf_for(station), state}

  def handle_call({:fetch_region, region}, {_from, _ref}, state), do:
    {:reply, metar_taf_for(Region.stations_for(region)), state}

  def handle_cast(:stop, state), do:
    {:stop, :normal, state}

  ####################
  # Helper Functions #
  ####################

  defp metar_taf_for(stations), do:
    {:ok, stations |> scrape |> transform_xml} # stations: a string of station ids separated by a space

  defp scrape(station) when is_list(station), do:
    Enum.join(station, ",") |> scrape

  defp scrape(station) when is_binary(station) do
    case HTTPoison.get(url_for_metar(station)) do
      {:ok, %{ status_code: 200, body: body}} ->
        body
      {:error, %{ reason: reason }} ->
        {:error, reason}
      _ -> {:error, "Unknown error"}
    end
  end

  defp transform_xml(xml_doc) do
    import SweetXml
    xml_doc
    |> xpath(~x"//METAR"l,
        station_id:       ~x"./station_id/text()",
        raw_text:         ~x"./raw_text/text()",
        metar_type:       ~x"./metar_type/text()",
        elevation_m:      ~x"./elevation_m/text()",
        altim_in_hg:      ~x"./altim_in_hg/text()",
        longitude:        ~x"./longitude/text()",
        latitude:         ~x"./latitude/text()",
        observation_time: ~x"./observation_time/text()",
        flight_category:  ~x"./flight_category/text()",
        sea_level_pressure_mb: ~x"./sea_level_pressure_mb/text()"
      )
      |> Enum.group_by(&(&1.station_id), &(&1))
      |> Enum.map(fn {station, reports} ->
           [current | history] = reports
           %Station{
              station: station |> List.to_string,
              elevation_m: current.elevation_m,
              longitude: current.longitude,
              latitude: current.latitude,
              latest_observation_time: current.observation_time,
              flight_category: current.flight_category,
              sea_level_pressure_mb: current.sea_level_pressure_mb,
              reports: %{
                current: current |> Map.get(:raw_text),
                history: history |> Enum.map(&Map.get(&1, :raw_text))
              }
            }
         end)
  end

  defp url_for_metar(station), do:
    "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=#{station}&hoursBeforeNow=4"

  def terminate(reason, state) do
    IO.puts "server terminated for #{inspect reason}"
    state
  end
end
