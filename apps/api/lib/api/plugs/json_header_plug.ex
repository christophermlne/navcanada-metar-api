defmodule Plug.JSONHeaderPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    put_resp_content_type(conn, "application/json")
  end
end
