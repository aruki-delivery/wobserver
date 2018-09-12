defmodule Wobserver2.Web.ClientSocket do
  @moduledoc ~S"""
  Low level WebSocket handler

  Connects to the Javascript websocket and parses all requests.

  Example:
    ```elixir
    defmodule Wobserver2.Web.Client do
      use Wobserver2.Web.ClientSocket

      alias Wobserver2.System

      def client_init do
        {:ok, %{}}
      end

      def client_handle(:hello, state) do
        {:reply, :ehlo, state}
      end

      def client_info(:update, state) do
        {:noreply, state}
      end
    end
    ```
  """

  require Logger

  alias Wobserver2.Util.Node.Discovery
  alias Wobserver2.Util.Node.Remote
  alias Wobserver2.Web.ClientSocket

  @typedoc "Response to browser."
  @type response ::
          {:reply, atom | list(atom), any, any}
          | {:reply, atom | list(atom), any}
          | {:noreply, any}

  @doc ~S"""
  Initalizes the WebSocket.

  Return {`:ok`, initial state} or {`:ok`, initial state, socket timeout}.
  """
  @callback client_init :: {:ok, any} | {:ok, any, non_neg_integer}
  @doc ~S"""
  Handles messages coming from the WS client.

  Return browser response.
  """
  @callback client_handle(atom | {atom, any}, any) :: ClientSocket.response()
  @doc ~S"""
  Handles messages coming from other processes.

  Return browser response.
  """
  @callback client_info(any, any) :: ClientSocket.response()

  defmacro __using__(_) do
    quote do
      import Wobserver2.Web.ClientSocket, only: :functions

      @behaviour Wobserver2.Web.ClientSocket

      @timeout 60_000

      ## Init / Shutdown

      @doc ~S"""
      Initialize the websocket connection.

      The `req` cowboy request and `options` are passed
      """
      @spec init(:cowboy_req.req(), any) :: {:cowboy_websocket, :cowboy_req.req(), any}
      def init(req, options) do
        {:cowboy_websocket, req, options}
      end

      @doc ~S"""
      Initialize the websocket connection by calling the implementing client.

      State is received
      """
      @spec websocket_init(any) :: {:ok, any}
      def websocket_init(state) do
        case client_init() do
          {:ok, state, _timeout} ->
            {:ok, %{state: state, proxy: nil}}

          {:ok, state} ->
            {:ok, %{state: state, proxy: nil}}
        end
      end

      ## Incoming from client / browser
      @doc ~S"""
      Handles incoming messages from the websocket client.

      The `message` is parsed and passed on to the client, which responds with an update `state` and possible reply.
      """
      @spec websocket_handle(
              {:text, String.t()},
              state :: any
            ) ::
              {:reply, {:text, String.t()}, any}
              | {:ok, any}
      def websocket_handle(message, state)

      def websocket_handle({:text, command}, state = %{proxy: nil}) do
        case parse_command(command) do
          {:setup_proxy, name} ->
            setup_proxy(name, state)

          :nodes ->
            {:reply, :nodes, Discovery.discover(), state.state}
            |> send_response(state)

          parsed_command ->
            parsed_command
            |> client_handle(state.state)
            |> send_response(state)
        end
      end

      def websocket_handle({:text, command}, state) do
        case parse_command(command) do
          {:setup_proxy, name} ->
            setup_proxy(name, state)

          :nodes ->
            {:reply, :nodes, Discovery.discover(), state.state}
            |> send_response(state)

          parsed_command ->
            send(state.proxy, {:proxy, command})
            {:ok, state}
        end
      end

      ## Outgoing
      @doc ~S"""
      Handles incoming messages from processes.

      The `message` is passed on to the client, which responds with an update `state` and possible reply.

      The `req` is ignored.
      """
      @spec websocket_info(
              {timeout :: any, ref :: any, msg :: any},
              state :: any
            ) ::
              {:reply, {:text, String.t()}, any}
              | {:ok, any}
      def websocket_info(message, state)

      def websocket_info({:proxy, data}, state) do
        {:reply, {:text, data}, state}
      end

      def websocket_info(:proxy_disconnect, state) do
        {:reply, :proxy_disconnect, state.state}
        |> send_response(%{state | proxy: nil})
      end

      def websocket_info(message, state) do
        message
        |> client_info(state.state)
        |> send_response(state)
      end
    end
  end

  # Helpers

  ## Command
  @doc ~S"""
  Parses the JSON `payload` to an atom command and map data.
  """
  @spec parse_command(payload :: String.t()) :: atom | {atom, any}
  def parse_command(payload) do
    command_data = Jason.decode!(payload)

    command =
      case String.split(command_data["command"], "/") do
        [one_command] -> one_command |> String.to_atom()
        list_of_commands -> list_of_commands |> Enum.map(&String.to_atom/1)
      end

    case command_data["data"] do
      "" -> command
      nil -> command
      data -> {command, data}
    end
  end

  @doc ~S"""
  Send a JSON encoded to the websocket client.

  The given `message` is JSON encoded (exception: `:noreply`).
  The `socket_state` is used updated to reflect changes made by the client.
  The cowboy `req` is returned untouched.
  """
  @spec send_response(
          message ::
            {:noreply, any}
            | {:reply, atom | list(atom), any}
            | {:reply, atom | list(atom), map | list | String.t() | nil, any},
          socket_state :: map
        ) ::
          {:reply, {:text, String.t()}, map}
          | {:ok, map}
  def send_response(message, socket_state)

  def send_response({:noreply, state}, socket_state) do
    {:ok, %{socket_state | state: state}}
  end

  def send_response({:reply, type, message, state}, socket_state) do
    data = %{
      type: uniform_type(type),
      timestamp: :os.system_time(:seconds),
      data: message
    }

    case Jason.encode(data) do
      {:ok, payload} ->
        {:reply, {:text, payload}, %{socket_state | state: state}}

      {:error, error} ->
        Logger.warn(
          "Wobserver2.Web.ClientSocket: Can't send message, reason: #{inspect(error)}, message: #{
            inspect(message)
          }"
        )

        {:ok, %{socket_state | state: state}}
    end
  end

  def send_response({:reply, type, state}, socket_state) do
    send_response({:reply, type, nil, state}, socket_state)
  end

  @doc """
  Sets up a websocket proxy to a given `proxy`.

  The `state` is modified to add in the new proxy
  """
  @spec setup_proxy(proxy :: String.t(), state :: map) ::
          {:reply, {:text, String.t()}, map}
          | {:ok, map}
  def setup_proxy(proxy, state) do
    connected =
      proxy
      |> Discovery.find()
      |> Remote.socket_proxy()

    case connected do
      {:error, message} ->
        {:reply, :setup_proxy, %{error: message}, state.state}
        |> send_response(state)

      {pid, "local"} ->
        if state.proxy != nil, do: send(state.proxy, :disconnect)

        name = Discovery.local().name

        {
          :reply,
          :setup_proxy,
          %{success: "Connected to: #{name}", node: name},
          state.state
        }
        |> send_response(%{state | proxy: pid})

      {pid, name} ->
        {
          :reply,
          :setup_proxy,
          %{success: "Connected to: #{name}", node: name},
          state.state
        }
        |> send_response(%{state | proxy: pid})
    end
  end

  @spec uniform_type(type :: atom | list(atom)) :: String.t()
  defp uniform_type(type)

  defp uniform_type(type) when is_atom(type), do: type |> Atom.to_string()

  defp uniform_type(type) when is_list(type) do
    type
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join("/")
  end
end
