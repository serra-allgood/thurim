defmodule ThurimClientApi.Router do
  use ThurimClientApi, :router

  pipeline :access_token do
    plug ThurimClientApi.Plugs.ExtractAccessToken
    plug ThurimClientApi.Plugs.RequireAccessToken
  end

  pipeline :interactive_auth do
    plug ThurimWeb.Plugs.InteractiveAuth
  end

  scope "/v1", ThurimClientApi do
    pipe_through :interactive_auth
    post "/login/get_token", SessionController, :get_token
  end

  scope "/v3", ThurimClientApi do
    pipe_through :interactive_auth

    post "/account/deactivate", AccountController, :deactivate
    post "/account/password", AccountController, :change_password

    post "/register", RegistrationController, :register
  end

  scope "/v3", ThurimClientApi do
    # Public
    post "/account/password/email/requestToken", AccountController, :email
    post "/account/password/msisdn/requestToken", AccountController, :msisdn

    get "/login", SessionController, :login_types
    post "/login", SessionController, :login
    post "/refresh", SessionController, :refresh

    get "/register/available", RegistrationController, :available
    post "/register/email/requestToken", RegistrationController, :email
    post "/register/msisdn/requestToken", RegistrationController, :msisdn

    # Authenticated
    pipe_through :access_token
    post "/logout/all", SessionController, :logout_all
    post "/logout", SessionController, :logout
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
