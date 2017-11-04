# Task.async(fn -> :poolboy.transaction(:worker, fn(pid) -> MetarScraper.Worker.get_metars_for_station(pid, "CYYZ") end, 10000) end)
defmodule MetarScraper.Server do
  use GenServer

  alias MetarScraper.Worker

  ## Client Api
  def start_link(opts \\ []), do:
    GenServer.start_link(__MODULE__, :ok, opts)

  # def get(pid, station), do:
  #   GenServer.call(pid, {:get, station})

  ## Server Callbacks
  def init(:ok) do
    # Task.async(fn -> :poolboy.transaction(:worker, fn(pid) -> MetarScraper.Worker.get_metars_for_station(pid, "CYYZ") end, 10000) end)
    {:ok, %{ data: initialize_data_for([:ontario_quebec, :arctic])}}
  end

  # def handle_call({:get, station}, {_from, _ref}, state) do
  #   {:reply, [], []}
  # end

  ## Helper Functions
  defp initialize_data_for(regions) do
    regions
    |> Enum.map(&Task.async(fn ->
         :poolboy.transaction(:scraper_worker_pool, fn (pid) ->
           Worker.get_metars_for_region(pid, &1)
         end, 10000)
       end))
    |> Enum.map(&Task.await/1)
  end
end
