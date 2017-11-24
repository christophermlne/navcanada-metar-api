defmodule MetarService.Server do
  use GenServer

  alias MetarService.{Worker,Region,Station}

  @refresh_interval 1000 * 60 * 10 * 6 # 1 hour

  ##############
  # Client API #
  ##############

  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def get(station), do:
    GenServer.call(__MODULE__, {:get, station})

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    IO.puts "performing initial scrape"
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:ok, update_data()}
  end

  def handle_call({:get, station}, {_from, _ref}, state), do:
    {:reply, get_station_report(station, state), state}

  def handle_cast(:stop, state), do:
    {:stop, :normal, state}

  def handle_info(:refresh_data, _state) do
    IO.puts "performing scheduled scrape"
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:noreply, update_data()}
  end

  def handle_info(:manually_refresh_data, _state) do
    IO.puts "performing manual scrape"
    {:noreply, update_data()}
  end

  ####################
  # Helper Functions #
  ####################

  defp update_data() do
    # TODO update data instead of just replacing it (accumulate history)
    %{ retrieved_at: timestamp(),
      data: %{
        metar: get_metar_data_for_regions(),
        taf: get_taf_data()
      }
    }
  end

  defp get_tafs_asynchronously() do
    Task.async(fn ->
       :poolboy.transaction(:scraper_worker_pool, fn (pid) ->
         case Worker.get_tafs_for_station(pid, "CY") do
           {:ok, result} -> result
         end
       end, 10000)
    end)
  end

  defp get_metars_asynchronously(region) do
    Task.async(fn ->
     :poolboy.transaction(:scraper_worker_pool, fn (pid) ->
       case Worker.get_metars_for_region(pid, region) do
         {:ok, result} -> result
       end
     end, 10000) end)
  end

  defp get_taf_data() do
    get_tafs_asynchronously()
    |> Task.await
  end

  defp get_metar_data_for_regions() do
    Region.names()
    |> Enum.map(&get_metars_asynchronously(&1))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce([], fn(x, acc) -> x ++ acc end) # TODO adjust worker response so this can be removed
  end

  defp get_station_report(station, data) do
    with {:ok, valid_station} <- Station.valid_id(station),
         {:ok, metar} <- get_metar_from_data(valid_station, data),
         {:ok, taf}   <- maybe_get_taf_from_data(valid_station, data)
    do
      {:ok, %{data: %{metar: metar, taf: taf},
              retrieved_at: Map.get(data, :retrieved_at)}}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp get_metar_from_data(station, data) do
    case data[:data][:metar] |> Enum.find(&(Map.get(&1, :station) == station)) do
      nil -> {:error, "Report not available."}
      metar-> {:ok, metar}
    end
  end

  defp maybe_get_taf_from_data(station, data) do
    case Map.get(data[:data][:taf], String.to_charlist(station)) do
      nil -> {:ok, "TAF not available for this station."}
      taf -> {:ok, taf}
    end
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
