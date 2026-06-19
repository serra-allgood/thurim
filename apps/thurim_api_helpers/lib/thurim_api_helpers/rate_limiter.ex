defmodule ThurimApiHelpers.RateLimiter do
  @callback get_scale(action :: atom()) :: pos_integer()
  @callback get_limit(action :: atom()) :: pos_integer()

  defmacro __using__(_options) do
    quote do
      import Plug.Conn

      alias ThurimApiHelpers.{
        RateLimit,
        RateLimit.RateLimitBehaviour,
        RateLimit.RateLimitInfo,
        RateLimit.RateLimitKey
      }

      @behaviour unquote(__MODULE__)

      def init(options), do: options

      def call(conn, _options) do
        %RateLimitInfo{scale: scale, limit: limit} =
          RateLimitInfo.new()
          |> RateLimitInfo.set_scale(get_scale(conn.assigns.action))
          |> RateLimitInfo.set_limit(get_limit(conn.assigns.action))

        conn.assigns.current_user.user_id
        |> RateLimitKey.get_key(conn.assigns.controller, conn.assigns.action)
        |> RateLimit.hit(scale, limit)
        |> case do
          {:allow, _count} ->
            conn

          {:deny, retry_after} ->
            conn
            |> put_resp_header("content-type", "application/json")
            |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
            |> send_resp(
              429,
              Jason.encode!(%{
                errcode: "M_LIMIT_EXCEEDED",
                error: "Rate limit exceeded for thie endpoint."
              })
            )
            |> halt()
        end
      end
    end
  end
end
