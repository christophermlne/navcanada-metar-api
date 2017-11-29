defmodule MetarService.Worker do
  use GenServer
  alias MetarService.{Station,Region}

  @adapter Application.get_env(:metar_service, :metar_data_adapter)

  ##############
  # Client API #
  ##############

  def start_link(opts \\ []), do:
    GenServer.start_link(__MODULE__, :ok, opts)

  def get_metars_for_station(pid, station), do:
    GenServer.call(pid, {:fetch_station, [station]})

  def get_metars_for_region(pid, region), do:
    GenServer.call(pid, {:fetch_region, region})

  def get_tafs_for_station(pid, station), do:
    GenServer.call(pid, {:fetch_tafs, station})

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

  def handle_call({:fetch_region, region}, {_from, _ref}, _state) do
    data = fetch(Region.stations_for(region), :metar, &extract_metars_from_xml/1)
    {:reply, data, %{}}
  end

  def handle_call({:fetch_tafs, stations}, {_from, _ref}, _state) do
    data = fetch(stations, :taf, &extract_tafs_from_xml/1)
    {:reply, data, %{}}
  end

  def handle_cast(:stop, state), do:
    {:stop, :normal, state}

  ####################
  # Helper Functions #
  ####################

  defp fetch(stations, report_type, xml_parse_fun) do
    case stations |> scrape(report_type) do
      {:ok, xml} -> {:ok, xml_parse_fun.(xml)}
      {:error, msg} -> {:error, msg}
    end
  end

  defp scrape(stations, report_type) when is_list(stations), do:
    Enum.join(stations, ",") |> scrape(report_type)

  defp scrape(stations, report_type) when is_binary(stations) do
    case @adapter.get(stations, report_type) do
      {:ok, response} -> {:ok, response}
      {:error, msg} -> {:error, msg}
    end
  end

  defp extract_tafs_from_xml(xml_doc) do
    import SweetXml
    xml_doc
    |> xpath(~x"//TAF"l,
       station_id: ~x"./station_id/text()",
       raw_taf:   ~x"./raw_text/text()")
    |> Enum.group_by(&(&1.station_id), &(&1.raw_taf))
  end

  defp extract_metars_from_xml(xml_doc) do
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

  def terminate(reason, state) do
    IO.puts "server terminated for #{inspect reason}"
    state
  end
end
