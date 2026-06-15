defmodule ThurimClientApi.Plugs.RateLimiters.AccountController do
  use ThurimApiHelpers.RateLimiter

  @impl true
  def get_limit(_action), do: 1

  @impl true
  def get_scale(_action), do: :timer.minutes(1)
end
