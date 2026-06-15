defmodule ThurimClientApi.Plugs.RateLimiters.RegistrationController do
  use ThurimApiHelpers.RateLimiter

  @impl true
  def get_limit(action) when action in [:register], do: 1

  @impl true
  def get_limit(action) when action in [:available], do: 10

  @impl true
  def get_scale(action) when action in [:register],
    do: :timer.minutes(1)

  @impl true
  def get_scale(action) when action in [:available],
    do: :timer.seconds(30)
end
