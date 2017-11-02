defmodule MetarScraper.Station do
  # TODO should this be named __MODULE.Aerodrome or something else ??
  @enforce_keys [:station, :current, :history, :taf]
  defstruct station: nil, region: nil, current: nil, history: [], taf: nil

  def fake do
    %__MODULE__{current: "", history: [], region: :ontario_quebec, station: :CYYZ, taf: ""}
  end
end
