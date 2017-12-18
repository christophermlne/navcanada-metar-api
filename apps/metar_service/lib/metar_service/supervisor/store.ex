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

  def find(:station, station_id) do
    case :ets.lookup(:station_data, station_id) do
      [] -> {:error, "Station data not available."}
      [{_, station}] -> {:ok, station}
    end
  end

  def put(:taf, station_id, forecast), do:
    GenServer.call(__MODULE__, {:put_taf, station_id, forecast})

  def put(:metar, station_id, reports), do:
    GenServer.call(__MODULE__, {:put_metar, station_id, reports})

  def put(:station, station_id, reports), do:
    GenServer.call(__MODULE__, {:put_station, station_id, reports})

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    for table_name <- [:taf_data, :metar_data, :station_data], do:
      :ets.new(table_name, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  def handle_call({:put_taf, station_id, forecast}, {_from, _ref}, state) do
    taf = :ets.insert(:taf_data, {station_id, forecast})
    {:reply, taf, state}
  end

  def handle_call({:put_metar, station_id, reports}, {_from, _ref}, state) do
    metar = :ets.insert(:metar_data, {station_id, reports})
    {:reply, metar, state}
  end

  def handle_call({:put_station, station_id, metar}, {_from, _ref}, state) do
    station = {station_id, %{
      elevation_m: List.to_float(metar.elevation_m),
      latitude: metar.latitude,
      longitude: metar.longitude
    }}
    :ets.insert(:station_data, station)
    {:reply, station, state}
  end

  ####################
  # Helper Functions #
  ####################
end
