defmodule MetarService.Adapters.Stations do
  @base_url "https://en.wikipedia.org/w/api.php?"
  @base_params "action=query&format=json"
  @station_list_title"&titles=List_of_airports_by_ICAO_code:_C"
  @content_params "&prop=revisions&rvprop=content&rvsection=0&rvparse"
  @link_params "&prop=links"

  #URL for retreiving data for one station ?prop=revisions&rvprop=content&titles=108 Mile Ranch
  def get(titles, :links),   do: link_url(titles)    |> get
  def get(titles, :content), do: content_url(titles) |> get

  defp get(url) do
    case HTTPoison.get(url) do
      {:ok, %{ status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %{ status_code: status_code, body: body}} ->
        {:error, "Status code: #{status_code}, Body: #{body}"}
      {:error, %{ reason: reason }} ->
        {:error, reason}
    end
  end

  defp link_url(titles), do:
    @base_url <> @base_params <> @link_params <> "#{normalize_titles(titles)}"

  defp content_url(titles), do:
    @base_url <> @base_params <> @content_params <> "#{normalize_titles(titles)}"

  defp normalize_titles(titles) when is_list(titles), do:
    # wikipedia api: You can normalize a list of page titles by removing duplicates and sorting the titles alphabetically
    titles |> Enum.sort |> Enum.dedup |> Enum.join("|") |> normalize_titles

  defp normalize_titles(title), do:
    "&titles=#{URI.encode(title)}"

  def extract_content(response) do
    with {:ok, decoded} <- Poison.decode(response),
         page <- get_in(decoded, ["query", "pages"])
    do
         id = Map.keys(page) |> List.first
         page[id]["revisions"] |> List.first |> Map.get("*")
    else
      _ -> :error
    end
  end

  def split_into_info_box_and_content(wikitext) do

  end

  defp extract_links() do
    # TODO parsing function to extract links
  end
end
