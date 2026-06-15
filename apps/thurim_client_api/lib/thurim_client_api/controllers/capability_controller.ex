defmodule ThurimClientApi.CapabilityController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimiters.CapabilityController

  def index(conn, _params) do
    json_error(conn, :t_not_implemented)
  end
end
