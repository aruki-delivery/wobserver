defmodule Wobserver2.Web.Router do
  @moduledoc ~S"""
  Main router.

  Splits into two paths:
    - `/api`, for all json api calls, handled by `Wobserver2.Web.Router.Api`.
    - `/`, for all static assets, handled by `Wobserver2.Web.Router.Static`.
  """

  use Wobserver2.Web.Router.Base

  forward("/api", to: Wobserver2.Web.Router.Api)
  forward("/metrics", to: Wobserver2.Web.Router.Metrics)
  forward("/", to: Wobserver2.Web.Router.Static)
end
