defmodule MetarService.Store do
  use GenServer

  ##############
  # Client API #
  ##############

  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def find(:taf, station_id) do
    case :ets.lookup(:taf_data, station_id) do
      [] -> {:ok, "TAF not available for this station."}
      [{_, taf}] -> {:ok, taf}
    end
  end

  def find(:metar, station_id) do
    case :ets.lookup(:metar_data, station_id) do
      [] -> {:error, "Report not available."}
      [{_, metar}] -> {:ok, metar}
    end
  end

  def put(:taf, station_id, forecast), do:
    GenServer.call(__MODULE__, {:put_taf, station_id, forecast})

  def put(:metar, station_id, reports), do:
    GenServer.call(__MODULE__, {:put_metar, station_id, reports})

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    :ets.new(:taf_data, [:set, :protected, :named_table])
    :ets.new(:metar_data, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  def handle_call({:put_taf, station_id, forecast}, {_from, _ref}, _state) do
    taf = :ets.insert(:taf_data, {station_id, forecast})
    {:reply, taf, %{}}
  end

  def handle_call({:put_metar, station_id, reports}, {_from, _ref}, _state) do
    metar = :ets.insert(:metar_data, {station_id, reports})
    {:reply, metar, %{}}
  end

  ####################
  # Helper Functions #
  ####################

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
