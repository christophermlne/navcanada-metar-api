defmodule MetarServiceTest do
  use ExUnit.Case
  doctest MetarService

  test "it scraps" do
    assert MetarService.run() == "/home/christopher/Desktop/screenshot1.png"
  end
end
