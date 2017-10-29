defmodule MetarScraper.Worker do
  use GenServer
  use Hound.Helpers
  alias Hound.Helpers.{Element}

  @url "https://flightplanning.navcanada.ca/cgi-bin/CreePage.pl?Langue=anglais&Page=Fore-obs%2Fmetar-taf-map&TypeDoc=html"
  @stations %{ontario_quebec: "CYYW CYND CYAT CYOW CYLA CYPO CYBG CYWA CYTL CYPQ CYBN CYPL CYLD CYQB CYCK CYRL CYMT CYRJ CYHD CYUY CYXR CZSJ CZEM CYSK CYER CYZR CYGQ CYAM CYZE CYKL CYHM CYSC CYPH CYXL CYYU CYSN CYQK CYSB CYGK CYTQ CYKF CYTJ CYVP CYQT CYGW CYTS CYGL CYTZ CYAD CYKZ CYAH CYYZ CYLH CYOO CYXU CYTR CYSP CYRQ CYNM CYMU CYMX CYVO CYUL CYOY CYHU CWQG CYMO CYKQ CYQA CYXZ CZMD CYNC CYHH CYVV CYYB CYQG CYKP"}

  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_metars(pid, station) do
    GenServer.call(pid, {:metar, station})
  end

  def get_metars_for_region(pid, region) do
    GenServer.call(pid, {:region_metar, region})
  end


  def clear_cache(pid) do
    GenServer.call(pid, {:clear_cache})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:clear_cache}, {_from, _ref}, _state) do
    {:reply, :ok, %{}}
  end

  def handle_call({:metar, station}, {_from, _ref}, state) do
    metars = metar_taf_for(station)
    {:reply, metars, metars}
  end

  def handle_call({:region_metar, region}, {_from, _ref}, state) do
    resp = metar_taf_for(Map.get(@stations, region))
    {:reply, resp, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  ## Helper Functions
  defp metar_taf_for(station) do
    report = scrape(station)
    stations = station |> String.split(" ") |> List.wrap

    {:ok,
      %{
        :METAR => stations |> Enum.map(&(extract(report, &1, :metar))),
        :TAF =>   stations |> Enum.map(&(extract(report, &1, :taf)))
      }
    }
  end

  defp scrape(station) do
    Hound.start_session

    navigate_to @url

    input = find_element(:name, "Stations")
    input |> fill_field(station)
    input |> submit_element()

    find_element(:xpath, "//body") |> Element.inner_text
  end

  defp extract(text, station, :metar) do
    {:ok, regex} = Regex.compile("METAR #{station}.+")
    regex
    |> extract(text)
  end

  defp extract(text, station, :taf) do
    {:ok, regex} = Regex.compile("TAF #{station}.+")
    regex
    |> extract(text)
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
