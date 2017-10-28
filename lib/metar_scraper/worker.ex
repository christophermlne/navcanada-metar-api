defmodule MetarScraper.Worker do
  use Hound.Helpers
  alias Hound.Helpers.{Element}

  @url "https://flightplanning.navcanada.ca/cgi-bin/CreePage.pl?Langue=anglais&Page=Fore-obs%2Fmetar-taf-map&TypeDoc=html"

  def metars_for(station \\ "CYKF"), do:
    get_report(station) |> extract(station, :metar)

  def taf_for(station \\ "CYKF"), do:
    get_report(station) |> extract(station, :taf)

  defp get_report(station) do
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
end
