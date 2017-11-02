defmodule MetarScraper.Station do
  @enforce_keys [:station, :region, :current, :history, :taf]
  defstruct station: nil, region: nil, current: nil, history: [], taf: nil

  def fake do
    %__MODULE__{current: "", history: [], region: :ontario_quebec, station: :CYYZ, taf: ""}
  end
end
