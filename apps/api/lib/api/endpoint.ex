defmodule Api.Endpoint do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug Plug.JSONHeaderPlug
  plug :match
  plug :dispatch

  def init(options) do
    options
  end

  def start_link do
    # NOTE: This starts Cowboy listening on the default port of 4000
    {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [])
  end

  get "/search" do
    {status, body} =
    case conn.params do
      %{"query" => query} ->
        {200, Poison.encode!%{response: search_station(query)}
      }
      _ ->
        {422, Poison.encode!%{response: "nope."}}
    end
    conn # delete
    send_resp(conn, status, body)
  end

  get "/metar" do
    {status, body} =
    case conn.params do
      %{"station" => station} ->
        {200, Poison.encode!(%{ response: find_station(station)}) }
      _ ->
        {422, missing_station()}
    end
    send_resp(conn, status, body)
  end

  get _ do
    send_resp(conn, 422, Poison.encode!(%{ response: %{ error: "Bad request"}}))
  end

  defp find_station(station) do
    case MetarService.get(station) do
      {:ok, data } -> data
      {:error, msg} -> %{ error: msg}
    end
  end

  defp search_station(query) do
    MetarService.search(query)
  end

  defp missing_station do
    Poison.encode!(%{ response: %{ error: "Expected a \"station\" key" }})
  end
end
