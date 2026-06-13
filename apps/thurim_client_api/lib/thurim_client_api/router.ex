defmodule ThurimClientApi.Router do
  use ThurimClientApi, :router

  pipeline :access_token do
    plug ThurimClientApi.Plugs.ExtractAccessToken
    plug ThurimClientApi.Plugs.RequireAccessToken
  end

  pipeline :interactive_auth do
    plug ThurimWeb.Plugs.InteractiveAuth
  end

  scope "/v3", ThurimClientApi do
    pipe_through :interactive_auth

    post "/register", RegistrationController, :register
  end

  scope "/v3", ThurimClientApi do
    # Public
    get "/register/available", RegistrationController, :available
    post "/login", SessionController, :login
    get "/login/sso/redirect", SsoController, :redirect

    # Authenticated
    pipe_through :access_token
    get "/sync", SyncController, :sync
    post "/logout", SessionController, :logout
    get "/account/whoami", AccountController, :whoami
    # ...etc
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:thurim_client_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ThurimClientApi.Telemetry
    end
  end
end
