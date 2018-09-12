defmodule Wobserver2.Web.Router.System do
  @moduledoc ~S"""
  System router.

  Returns the following resources:
    - `/` => `Wobserver2.System.overview/0`.
    - `/architecture` => `Wobserver2.System.Info.architecture/0`.
    - `/cpu` => `Wobserver2.System.Info.cpu/0`.
    - `/memory` => `Wobserver2.System.Memory.usage/0`.
    - `/statistics` => `Wobserver2.System.Statistics.overview/0`.
  """

  use Wobserver2.Web.Router.Base

  alias Wobserver2.System
  alias System.Info
  alias System.Memory
  alias System.Statistics

  get "/" do
    System.overview()
    |> send_json_resp(conn)
  end

  get "/architecture" do
    Info.architecture()
    |> send_json_resp(conn)
  end

  get "/cpu" do
    Info.cpu()
    |> send_json_resp(conn)
  end

  get "/memory" do
    Memory.usage()
    |> send_json_resp(conn)
  end

  get "/statistics" do
    Statistics.overview()
    |> send_json_resp(conn)
  end

  match _ do
    conn
    |> send_resp(404, "Pages not Found")
  end
end
