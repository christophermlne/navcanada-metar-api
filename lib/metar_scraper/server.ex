defmodule MetarScraper.Server do
  use GenServer

  alias MetarScraper.{Worker,Region}

  @refresh_interval 600000 # 10 minutes

  ## Client Api
  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def get(pid, station), do:
    GenServer.call(pid, {:get, station})


  ## Server Callbacks
  def init(:ok) do
    IO.puts "performing initial scrape"
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:ok, %{ data: get_data_for_regions()}}
  end

  def handle_call({:get, station}, {_from, _ref}, state), do:
    {:reply, get_station_report(station, state), state}

  def handle_cast(:stop, state), do:
    {:stop, :normal, state}

  def handle_info(:refresh_data, _state) do
    IO.puts "performing scheduled scrape"
    Process.send_after(self(), :refresh_data, @refresh_interval)
    {:noreply, %{ data: get_data_for_regions()}}
  end


  ## Helper Functions
  defp get_data_for_regions() do
    Region.names()
    |> Enum.map(&Task.async(fn ->
         :poolboy.transaction(:scraper_worker_pool, fn (pid) ->
           case Worker.get_metars_for_region(pid, &1) do
             {:ok, result} -> result
           end
         end, 10000)
       end))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce([], fn(x, acc) -> x ++ acc end) # TODO adjust worker response so this can be removed
  end

  def get_station_report(station, data) do
    Enum.find(data[:data], fn (report) ->
      Map.get(report, :station) == station
    end)
  end
end
