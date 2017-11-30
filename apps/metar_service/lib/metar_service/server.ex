# TODO Better Separation of Responsibilities:
# 1) Server should only provide the public interface for getting data and should not coordinate the collection of the data
# 2) Store or Repo should manage the data
# 3) Coordinator should manage the workers and update the Store or Repo
##########################
# STEP 1) move server state into a Store GenServer and update Server methods to retrieve data from the Store
# STEP 2) move worker management functions into a WorkerCoordinator class
defmodule MetarService.Server do
  alias MetarService.Station

  def get(station) do
    data = :ets.lookup(:metar_data, :data)[:data]

    get_station_report(station, data)
  end

  defp get_station_report(station, data) do
    with {:ok, valid_station} <- Station.valid_id(station),
         {:ok, metar} <- get_metar_from_data(valid_station, data),
         {:ok, taf}   <- maybe_get_taf_from_data(valid_station, data)
    do
      {:ok, %{data: %{metar: metar, taf: taf},
              retrieved_at: Map.get(data, :retrieved_at)}}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp get_metar_from_data(station, data) do
    case data[:data][:metar] |> Enum.find(&(Map.get(&1, :station) == station)) do
      nil -> {:error, "Report not available."}
      metar-> {:ok, metar}
    end
  end

  defp maybe_get_taf_from_data(station, data) do
    case Map.get(data[:data][:taf], String.to_charlist(station)) do
      nil -> {:ok, "TAF not available for this station."}
      taf -> {:ok, taf}
    end
  end

  defp timestamp, do: DateTime.utc_now |> DateTime.to_iso8601
end
