defmodule MetarServiceStoreTest do
  use ExUnit.Case

  setup do
    {:ok, _} = MetarService.Store.start_link

    {:ok, %{}}
  end

  test "TAFS: it can store and retrieve TAFs" do
    MetarService.Store.put(:taf, "CYYZ", "CYYZ TAF")
    assert {:ok, "CYYZ TAF"} == MetarService.Store.find(:taf, "CYYZ")
  end

  test "TAFS: it return success message for missing TAFs with message" do
    assert {:ok, "TAF not available for this station."} == MetarService.Store.find(:taf, "CYFOOBAR")
  end

  test "METARS: it can store and retrieve METARS"  do
    MetarService.Store.put(:metar, "CYYZ", "CYYZ METAR")
    assert {:ok, "CYYZ METAR"} == MetarService.Store.find(:metar, "CYYZ")
  end

  test "METARS: missing metars return error tuple" do
    assert {:error, "Report not available."} == MetarService.Store.find(:metar, "CYYZ")
  end

  test "STATIONS: it returns error tuple for missing stations" do
    assert {:error, "Station data not available."} == MetarService.Store.find(:station, "CYYZ")
  end

  test "STATIONS: it can store and retrieve stations" do
    data = %{ elevation_m: '1.0', latitude: '1.0', longitude: '1.0' }

    MetarService.Store.put(:station, "CYYZ", data)
    {:ok, map} = MetarService.Store.find(:station, "CYYZ")

    assert is_map(map)
  end
end
