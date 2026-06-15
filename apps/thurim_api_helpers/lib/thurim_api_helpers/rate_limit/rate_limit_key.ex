defmodule ThurimApiHelpers.RateLimit.RateLimitKey do
  def get_key(user_id, controller, action), do: "#{controller}-#{action}:#{user_id}"
end
