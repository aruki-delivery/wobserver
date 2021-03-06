defmodule Wobserver2.Web.Router.Helper do
  @moduledoc ~S"""
  Helper methods for routers.
  """

  alias Plug.Conn

  @doc ~S"""
  Sends a JSON encoded response back to the client.

  The https status will be `200` or `500` if the given `data` can not be JSON encoded.

  The `conn` content type is set to `application/json`, only if the data could be encoded.
  """
  @spec send_json_resp(
          data :: atom | String.t() | map | list,
          conn :: Plug.Conn.t()
        ) :: Plug.Conn.t()
  def send_json_resp(data, conn)

  def send_json_resp(:page_not_found, conn) do
    conn
    |> Conn.send_resp(404, "Page not Found")
  end

  def send_json_resp(data, conn) do
    json = Jason.encode!(data)
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, json)
  end
end
