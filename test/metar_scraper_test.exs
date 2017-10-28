defmodule MetarScraperTest do
  use ExUnit.Case
  doctest MetarScraper

  test "it scraps" do
    assert MetarScraper.run() == "/home/christopher/Desktop/screenshot1.png"
  end
end
