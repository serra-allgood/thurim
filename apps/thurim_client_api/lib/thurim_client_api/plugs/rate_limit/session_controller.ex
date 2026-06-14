defmodule ThurimClientApi.Plugs.RateLimit.SessionController do
  use ThurimClientApi, :rate_limiter

  @impl RateLimitBehaviour
  def get_scale(action) when action in [:get_token, :login, :login_types, :refresh], do: :timer.minutes(1)

  @impl RateLimitBehaviour
  def get_limit(action) when action in [:get_token, :login, :refresh], do: 1

  @impl RateLimitBehaviour
  def get_limit(:login_types), do: 5
end
