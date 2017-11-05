defmodule MetarScraper.Worker do
  use GenServer
  use Hound.Helpers
  alias Hound.Helpers.Element
  alias MetarScraper.{Station,Region}

  @url "https://flightplanning.navcanada.ca/cgi-bin/CreePage.pl?Langue=anglais&Page=Fore-obs%2Fmetar-taf-map&TypeDoc=html"

  ## Client API
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


  ## Server Callbacks
  def init(:ok), do:
    {:ok, %{}}

  def handle_call({:clear_cache}, {_from, _ref}, _state), do:
    {:reply, :ok, %{}}

  def handle_call({:fetch_station, station}, {_from, _ref}, state) do
    metars = metar_taf_for(station)
    {:reply, metars, state}
  end

  def handle_call({:fetch_region, region}, {_from, _ref}, state) do
    resp = metar_taf_for(Region.stations_for(region))
    {:reply, resp, state}
  end

  def handle_cast(:stop, state), do:
    {:stop, :normal, state}


  ## Helper Functions
  defp metar_taf_for(stations) do
    report = scrape(stations) # stations must be a string of stations separated by a space

    {:ok, stations |> Enum.map(&(extract(report, &1, :metar)))}
  end

  defp scrape(station) when is_list(station), do:
    Enum.join(station, " ") |> scrape

  defp scrape(station) when is_binary(station) do
    Hound.start_session

    navigate_to @url

    input = find_element(:name, "Stations")
    input |> fill_field(station)
    input |> submit_element()

    find_element(:xpath, "//body") |> Element.inner_text
  end

  defp extract(text, station, :metar) do
    {:ok, metar_regex} = Regex.compile("(METAR|LWIS|SPECI) #{station}.+")
    {:ok, taf_regex} = Regex.compile("TAF #{station}.+")

    [current | history] = case extract(metar_regex, text) do
      [] -> [:error, :error]
      [current | nil] -> [current, []]
      [current | history] -> [current, history]
    end

    %Station{
      station: station,
      current: current,
      history: history,
      taf: extract(taf_regex, text)
    }
  end

  defp extract(regex, text) when is_binary(text) do
    strip = fn (line) ->
      line = String.replace(line, "\n", "")
      Regex.scan(regex, line)
      |> List.first
      |> List.first
    end

    text
    |> String.split("=")
    |> Enum.filter(&Regex.match?(regex, &1))
    |> Enum.map(&strip.(&1))
  end

  def terminate(reason, state) do
    IO.puts "server terminated for #{inspect reason}"
    state
  end
end
