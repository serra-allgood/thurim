defmodule ThurimGateway.Router do
  use ThurimGateway, :router

  # -------------------------------------------------------
  # Shared pipeline — runs for all /_matrix/* requests
  # -------------------------------------------------------
  pipeline :matrix do
    plug :accepts, ["json"]
  end

  # -------------------------------------------------------
  # /.well-known — handled directly in the gateway
  # -------------------------------------------------------
  scope "/.well-known/matrix", ThurimGateway do
    pipe_through :matrix
    get "/client", WellKnownController, :client
    get "/server", WellKnownController, :server
    get "/support", WellKnownController, :support
  end

  # -------------------------------------------------------
  # /_matrix/* — forwarded to sub-app Routers
  #
  # forward/4 strips the matched prefix before passing the
  # conn to the target router, so each sub-router sees paths
  # relative to its own scope root.
  # -------------------------------------------------------
  scope "/_matrix" do
    pipe_through :matrix

    forward "/client/v1/media", ThurimMedia.Router
    forward "/media", ThurimMedia.Router

    forward "/client", ThurimClientApi.Router

    forward "/federation", ThurimFederation.Router

    forward "/app", ThurimAppservice.Router

    forward "/key", ThurimFederation.Router
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:thurim_gateway, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ThurimGateway.Telemetry
    end
  end
end
