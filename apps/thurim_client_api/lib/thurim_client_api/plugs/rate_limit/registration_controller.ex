defmodule ThurimClientApi.Plugs.RateLimit.RegistrationController do
  use ThurimClientApi, :rate_limiter

	@impl RateLimitBehaviour
  def get_limit(action) when action in [:register], do: 1

	@impl RateLimitBehaviour
  def get_limit(action) when action in [:available], do: 10

  @impl RateLimitBehaviour
  def get_scale(action) when action in [:register],
    do: :timer.minutes(1)

	@impl RateLimitBehaviour
  def get_scale(action) when action in [:available],
    do: :timer.seconds(30)
end
