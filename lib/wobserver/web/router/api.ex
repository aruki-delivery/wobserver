defmodule Wobserver2.Web.Router.Api do
  @moduledoc ~S"""
  Main api router.

  Returns the following resources:
    - `/about` => `Wobserver2.about/0`.
    - `/nodes` => `Wobserver2.NodeDiscovery.discover/0`.

  Splits into the following paths:
    - `/system`, for all system information, handled by `Wobserver2.Web.Router.System`.

  All paths also include the option of entering a node name before the path.
  """

  use Wobserver2.Web.Router.Base

  alias Plug.Router.Utils

  alias Wobserver2.Allocator
  alias Wobserver2.Page
  alias Wobserver2.Table
  alias Wobserver2.Util.Application
  alias Wobserver2.Util.Process
  alias Wobserver2.Util.Node.Discovery
  alias Wobserver2.Util.Node.Remote
  alias Wobserver2.Web.Router.Api
  alias Wobserver2.Web.Router.System

  match "/nodes" do
    Discovery.discover()
    |> send_json_resp(conn)
  end

  match "/custom" do
    Page.list()
    |> send_json_resp(conn)
  end

  match "/about" do
    Wobserver2.about()
    |> send_json_resp(conn)
  end

  get "/application/:app" do
    app
    |> String.downcase()
    |> String.to_atom()
    |> Application.info()
    |> send_json_resp(conn)
  end

  get "/application" do
    Application.list()
    |> send_json_resp(conn)
  end

  get "/process" do
    Process.list()
    |> send_json_resp(conn)
  end

  get "/process/:pid" do
    pid
    |> Process.info()
    |> send_json_resp(conn)
  end

  get "/ports" do
    Wobserver2.Port.list()
    |> send_json_resp(conn)
  end

  get "/allocators" do
    Allocator.list()
    |> send_json_resp(conn)
  end

  get "/table" do
    Table.list()
    |> send_json_resp(conn)
  end

  get "/table/:table" do
    table
    |> Table.sanitize()
    |> Table.info(true)
    |> send_json_resp(conn)
  end

  forward("/system", to: System)

  match "/:node_name/*glob" do
    case glob do
      [] ->
        node_name
        |> String.to_atom()
        |> Page.call()
        |> send_json_resp(conn)

      # conn
      # |> send_resp(501, "Custom commands not implemented yet.")
      _ ->
        node_forward(node_name, conn, glob)
    end
  end

  match _ do
    conn
    |> send_resp(404, "Page not Found")
  end

  # Helpers

  defp node_forward(node_name, conn, glob) do
    case Discovery.find(node_name) do
      :local -> local_forward(conn, glob)
      {:remote, remote_node} -> remote_forward(remote_node, conn, glob)
      :unknown -> send_resp(conn, 404, "Node #{node_name} not Found")
    end
  end

  defp local_forward(conn, glob) do
    Utils.forward(
      var!(conn),
      var!(glob),
      Api,
      Api.init([])
    )
  end

  defp remote_forward(remote_node, conn, glob) do
    path =
      glob
      |> Enum.join()

    case Remote.api(remote_node, "/" <> path) do
      :error ->
        conn
        |> send_resp(500, "Node #{remote_node.name} not responding.")

      data ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, data)
    end
  end
end
