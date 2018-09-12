defmodule Wobserver2.Application do
  use Application
  require Logger
  require Wobserver2.Util.EnvHelper

  alias Wobserver2.Page
  alias Wobserver2.Util.Metrics

  @ref Module.concat([__MODULE__, "HTTP", "Ranch15", "Cowboy24"])
  @max_connections 300
  @timeout 30000
  @port Wobserver2.Util.EnvHelper.parse_port!("WOBSERVER_PORT", "8910")

  @doc ~S"""
  The port the application uses.
  """
  @spec port :: integer
  def port(), do: @port

  @doc ~S"""
  Starts `wobserver`.
  **Note:** both `type` and `args` are unused.
  """
  @spec start(term, term) ::
          {:ok, pid}
          | {:ok, pid, state :: any}
          | {:error, reason :: term}
  def start(_type, _args) do
    Logger.info("[#{__MODULE__}] Starting Wobserver2:#{@port} ")
    # Load pages and metrics from config
    Page.load_config()
    Metrics.load_config()

    children = [
      %{
        id: {:ranch_listener_sup, @ref},
        start:
          {:ranch_listener_sup, :start_link,
           [
             # supervisor id / ref
             @ref,
             # num_acceptors
             100,
             # ranch_protocol
             :ranch_tcp,
             [
               # ranch tcp configs
               port: @port,
               max_connections: @max_connections,
               keepalive: true,
               send_timeout: @timeout
             ],
             # cowboy <-> ranch protocol
             :cowboy_clear,
             %{
               # cowboy configs
               connection_type: :supervisor,
               middlewares: [
                 :cowboy_router,
                 :cowboy_handler
               ],
               env: %{
                 dispatch: [
                   {:_,
                    [
                      {"/ws", Wobserver2.Web.Client, []},
                      {:_, Cowboy2.Handler, {Wobserver2.Web.Router, []}}
                    ]}
                 ]
               },
               stream_handlers: [:cowboy_stream_h]
             }
           ]},
        restart: :permanent,
        shutdown: :infinity,
        type: :supervisor,
        modules: [:ranch_listener_sup]
      }
    ]

    opts = [strategy: :one_for_one, name: Wobserver2.Web.Supervisor]
    sup = Supervisor.start_link(children, opts)
    Logger.info("[#{__MODULE__}] Started Wobserver2:#{@port} successfully!")
    sup
  end

  def stop(_state), do: :ok
end
