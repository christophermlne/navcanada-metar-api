defmodule MetarService do
  defdelegate get(station), to: __MODULE__.Server
  defdelegate search(query), to: __MODULE__.Server
end
