defmodule MetarService do
  defdelegate get(station), to: __MODULE__.Server
end
