defmodule MetarService.Coordinator do
  use GenServer
  require Logger

  alias MetarService.{Worker,Region,Station,Store}

  @refresh_interval 1000 * 60 * 10 * 6 # 1 hour

  ##############
  # Client API #
  ##############

  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    Logger.info "#{__MODULE__}: Populating data..."
    Process.send_after(self(), :refresh_metar, 1)
    Process.send_after(self(), :refresh_taf, 5001)
    {:ok, %{
      metar_last_run: :never,
      taf_last_run: :never,
      station_last_run: :never,
      station_names_updated: :never
      }
    }
  end

  def handle_info(:refresh_metar, state) do
    Logger.info "#{__MODULE__}: Refreshing metar data..."
    Process.send_after(self(), :refresh_metar, @refresh_interval)
    update_metar_data()
    state = state |> Map.put(:metar_last_run, timestamp())
    state = state |> Map.put(:station_last_run, timestamp())
    {:noreply, state}
  end

  def handle_info(:refresh_taf, state) do
    Logger.info "#{__MODULE__}: Refreshing taf data..."
    Process.send_after(self(), :refresh_taf, @refresh_interval)
    update_taf_data()
    state = Map.put(state, :taf_last_run, timestamp())
    case state do
      %{station_names_updated: :never} ->
        Process.send_after(self(), :update_stations, 500)
      _ ->
        Logger.info "#{__MODULE__}: Stations already updated. Skipping."
    end
    {:noreply, state}
  end

  def handle_info(:update_stations, state) do
    # TODO if already updated then noop
    Logger.info "#{__MODULE__}: Updating station data..."
    update_station_data() # side effects!
    {:noreply, %{state | station_names_updated: true}}
  end

  ####################
  # Helper Functions #
  ####################

  defp update_station_data() do
    Station.names()
    |> Enum.each(&(Store.update(:station, &1)))
    Logger.info "#{__MODULE__}: Done updating Stations"
  end

  defp update_taf_data() do
    get_taf_data()
    |> Enum.each(fn (taf) ->
         {station, [forecast]} = taf
         Store.put(:taf, List.to_string(station), List.to_string(forecast))
       end)

    Logger.info "#{__MODULE__}: Done updating Taf"
  end

  defp update_metar_data() do
    metar_data = get_metar_data_for_regions()

    Enum.each(metar_data, fn (metar) ->
      Store.put(:metar, metar.station, metar)
      Store.put(:station, metar.station, metar)
    end)

    Logger.info "#{__MODULE__}: Done updating Metar"
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

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
