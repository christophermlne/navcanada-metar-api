defmodule MetarService.Store do
  use GenServer

  ##############
  # Client API #
  ##############

  def start_link(), do:
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def put(:taf, data), do:
    GenServer.call(__MODULE__, {:update_taf, data})

  def put(:metar, data), do:
    GenServer.call(__MODULE__, {:update_metar, data})

  ####################
  # Server Callbacks #
  ####################

  def init(:ok) do
    :ets.new(:taf_data, [:set, :protected, :named_table])
    :ets.new(:metar_data, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  # NOTE :ets.insert will replace data, insert_new will update
  def handle_call({:update_taf, data}, {_from, _ref}, _state) do
    :ets.insert(:taf_data, {:data, data})
    :ets.insert(:taf_data, {:retrieved_at, timestamp()})
    {:reply, data, %{}}
  end

  def handle_call({:update_metar, data}, {_from, _ref}, _state) do
    :ets.insert(:metar_data,  {:data, data})
    :ets.insert(:metar_data,  {:retrieved_at, timestamp()})
    {:reply, data, %{}}
  end

  ####################
  # Helper Functions #
  ####################

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
