defmodule MetarService.Store do
  use GenServer

  ##############
  # Client API #
  ##############

  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def put(:update_individual_taf, station_id, forecast), do:
    GenServer.call(__MODULE__, {:update_individual_taf, station_id, forecast})

  def put(:update_individual_metar, station_id, reports), do:
    GenServer.call(__MODULE__, {:update_individual_metar, station_id, reports})

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    :ets.new(:taf_data, [:set, :protected, :named_table])
    :ets.new(:metar_data, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  # NOTE :ets.insert will replace data, insert_new will update

  # updates an individual taf within the taf_data table
  def handle_call({:update_individual_taf, station_id, forecast}, {_from, _ref}, _state) do
    taf = :ets.insert(:taf_data, {station_id, forecast})
    {:reply, taf, %{}}
  end

  # updates an individual metar within the metar_data table
  def handle_call({:update_individual_metar, station_id, reports}, {_from, _ref}, _state) do
    metar = :ets.insert(:metar_data, {station_id, reports})
    {:reply, metar, %{}}
  end

  ####################
  # Helper Functions #
  ####################

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
