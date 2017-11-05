# Task.async(fn -> :poolboy.transaction(:worker, fn(pid) -> MetarScraper.Worker.get_metars_for_station(pid, "CYYZ") end, 10000) end)
defmodule MetarScraper.Server do
  use GenServer

  alias MetarScraper.{Worker,Region}

  ## Client Api
  def start_link(opts \\ []), do:
    GenServer.start_link(__MODULE__, :ok, opts)

  ## Server Callbacks
  def init(:ok) do
    {:ok, %{ data: initialize_data_for(Region.names())}}
  end

  ## Helper Functions
  def initialize_data_for(regions) do
    regions
    |> Enum.map(&Task.async(fn ->
         :poolboy.transaction(:scraper_worker_pool, fn (pid) ->
           case Worker.get_metars_for_region(pid, &1) do
             {:ok, result} -> result
           end
         end, 10000)
       end))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce([], fn(x, acc) -> x ++ acc end)
  end
end
