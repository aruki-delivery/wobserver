defmodule Wobserver2.Util.EnvHelper do
  @moduledoc false

  defmacro parse_port!(env, default) do
    quote bind_quoted: binding() do
      {port, ""} = Integer.parse(System.get_env(env) || default)
      port
    end
  end
end
