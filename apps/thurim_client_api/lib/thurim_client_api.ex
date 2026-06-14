defmodule ThurimClientApi do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ThurimClientApi, :controller
      use ThurimClientApi, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn
      import ThurimClientApi.Errors

      plug :assign_key_names

      defp assign_key_names(conn, _options) do
        conn
        |> assign(:action, action_name(conn))
        |> assign(:controller, controller_module(conn))
      end

      unquote(verified_routes())
    end
  end

  def rate_limiter do
    quote do
      import Plug.Conn

      alias ThurimClientApi.{
        RateLimit,
        RateLimit.RateLimitBehaviour,
        RateLimit.RateLimitInfo,
        RateLimit.RateLimitKey
      }

      @behaviour RateLimitBehaviour

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
            |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
            |> send_resp(429, [])
            |> halt()
        end
      end
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ThurimClientApi.Endpoint,
        router: ThurimClientApi.Router,
        statics: ThurimClientApi.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
