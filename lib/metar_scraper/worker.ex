defmodule MetarScraper.Worker do
  use GenServer
  use Hound.Helpers
  alias Hound.Helpers.{Element}
  alias MetarScraper.Station

  @url "https://flightplanning.navcanada.ca/cgi-bin/CreePage.pl?Langue=anglais&Page=Fore-obs%2Fmetar-taf-map&TypeDoc=html"

  @stations %{
    arctic:              ~w(CYLT CWGZ CYAB CYGZ CWEU CYIO CYEU CYRB),
    atlantic:            ~w(CYBC CYFT CZBF CYMH CWKW CYQM CWYK CYYY CWCA CYDP CYCA CYNA CYYG CYPD CZUM CWSA CYDF CSB2 CYFC CST5 CYCX CWZZ CYQX CYSJ CYGP LFVP CYYR CYZV CYZX CYAY CYAW CYYT CYHZ CYSL CYGV CYJT CYGR CYQY CYLU CWTU CWWU CYWK CCX2 CYQI CYBX),
    ontario_quebec:      ~w(CYYW CYND CYAT CYOW CYLA CYPO CYBG CYWA CYTL CYPQ CYBN CYPL CYLD CYQB CYCK CYRL CYMT CYRJ CYHD CYUY CYXR CZSJ CZEM CYSK CYER CYZR CYGQ CYAM CYZE CYKL CYHM CYSC CYPH CYXL CYYU CYSN CYQK CYSB CYGK CYTQ CYKF CYTJ CYVP CYQT CYGW CYTS CYGL CYTZ CYAD CYKZ CYAH CYYZ CYLH CYOO CYXU CYTR CYSP CYRQ CYNM CYMU CYMX CYVO CYUL CYOY CYHU CWQG CYMO CYKQ CYQA CYXZ CZMD CYNC CYHH CYVV CYYB CYQG CYKP),
    pacific:             ~w(CYXX CYCD CBBC CYYF CYBD CYZT CYCP CYPW CYBL CYXS CYCG CYPR CYCQ CYDC CWCL CYQZ CYIN CYRV CYQQ CYZP CYXC CYYD CYDQ CWSW CWDL CYSW CYDL CZST CYYE CYXT CYXJ CYAZ CYGE CYVR CYHE CYWH CYKA CYYJ CYLW CAW4 CWLY CBE9 CYZY CWAE CZMT CYWL CWWQ),
    prairies:            ~w(CYBV CYLL CYBR CYYL CYVT CYLJ CYYC CYXH CYBW CYMJ CYYQ CYBU CYOD CYQW CYDN CYNE CYEG CYPE CYED CZPC CZVL CYPG CYET CWIQ CYEN CYPA CYFO CYQF CYPY CYQR CYMM CYXE CYGX CYZH CYQU CYSF CYOJ CYYN CYIV CYBQ CWHN CYQD CYKJ CYTH CYKY CYZU CYVC CYWG CYQL CYQV),
    nunavut:             ~w(CYKO CYIK CYEK CYKG CYBK CYAS CWOB CYLC CWVD CYBB CWRF CWLX CYTE CYUT CWFD CYXP CWUP CYPX CWYM CYVM CYCS CYHA CYCY CYRT CYZS CWRH CWUW CWRX CYHK CYZG CYUX CYUS CYGT CYYH CYFB CYXN),
    yukon_and_northwest: ~w(CYKD CWKP CYXQ CWKM CYDB CYCO CYCB CYUJ CZCP CWLI CWPX CYLK CYVL CYMA CWXR CYVQ CYDA CYOC CWON CYPC CYWJ CYSY CYOA CYUA CZFA CWVH CYGH CYZW CYJF CYUB CZFM CZFN CYFR CYHI CYFS CYQH CYSM CYWE CYRA CYXY CWIL CYWY CYHY CYZF CYEV)
  }


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
    resp = metar_taf_for(Map.get(@stations, region))
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
