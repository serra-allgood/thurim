defmodule ThurimClientApi.RateLimit.RateLimitBehaviour do
  @callback get_scale(action :: atom()) :: pos_integer()
  @callback get_limit(action :: atom()) :: pos_integer()
end
