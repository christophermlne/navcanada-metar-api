defmodule MetarServiceStoreTest do
  use ExUnit.Case

  @tag :skip
  test "it can store and retrieve TAFs" do
    {:ok, _} = MetarService.Store.start_link

    MetarService.Store.put(:taf, "CYYZ", "CYYZ TAF")
    assert {:ok, "CYYZ TAF"} == MetarService.Store.find(:taf, "CYYZ")
  end
end
