defmodule MetarService.Coordinator do
  use GenServer

  alias MetarService.{Worker,Region,Store}

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
    IO.puts "#{__MODULE__}: Populating data..."
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:ok, update_data()}
  end

  def handle_info(:refresh_data, _state) do
    IO.puts "#{__MODULE__}: Refreshing data..."
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:noreply, update_data()}
  end

  ####################
  # Helper Functions #
  ####################

  defp update_data() do
    metar_data = get_metar_data_for_regions()
    taf_data = get_taf_data()

    Enum.each(metar_data, fn (metar) ->
      Store.put(:metar, metar.station, metar)
    end)

    Enum.each(taf_data, fn (taf) ->
      {station, [forecast]} = taf
      Store.put(:taf, List.to_string(station), List.to_string(forecast))
    end)

    IO.puts "#{__MODULE__}: Done"
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
end