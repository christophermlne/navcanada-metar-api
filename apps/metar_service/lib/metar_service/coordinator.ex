defmodule MetarService.Coordinator do
  use GenServer

  alias MetarService.{Worker,Region,Station}

  @refresh_interval 1000 * 60 * 10 * 6 # 1 hour

  ##############
  # Client API #
  ##############

  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def data(), do:
    GenServer.call(__MODULE__, :data)

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    # TODO move data into public read ets table and fire update asynchronously
    IO.puts "performing initial scrape"
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:ok, update_data()}
  end

  def handle_call(:data, {_from, _ref}, state), do:
    {:reply, state, state}

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

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
