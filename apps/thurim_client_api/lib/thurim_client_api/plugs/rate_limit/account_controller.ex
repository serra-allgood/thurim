defmodule ThurimClientApi.Plugs.RateLimit.AccountController do
  use ThurimClientApi, :rate_limiter

  @impl RateLimitBehaviour
  def get_limit(action) when action in [:deactivate, :change_password], do: 1

  @impl RateLimitBehaviour
  def get_scale(action) when action in [:deactivate, :change_password], do: :timer.minutes(1)
end
