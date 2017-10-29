defmodule MetarScraper.Worker do
  use GenServer
  use Hound.Helpers
  alias Hound.Helpers.{Element}

  @url "https://flightplanning.navcanada.ca/cgi-bin/CreePage.pl?Langue=anglais&Page=Fore-obs%2Fmetar-taf-map&TypeDoc=html"

  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_metars(pid, station) do
    GenServer.call(pid, {:metar, station})
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
    case Map.has_key?(state, station) do
      true ->
        # rudimentary caching (with no expiry)
        {:reply, Map.get(state, station), state}
      false ->
        case metar_taf_for(station) do
          {:ok, metars} ->
            new_state = Map.put(state, station, metars)
            {:reply, metars, new_state}
          _ ->
            {:reply, :error, "something went wrong"}
        end
    end
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  ## Helper Functions
  defp metar_taf_for(station) do
    report = get_page(station)
    {:ok,
      %{
        :METAR => extract(report, station, :metar),
        :TAF =>   extract(report, station, :taf)
      }
    }
  end

  defp get_page(station) do
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
