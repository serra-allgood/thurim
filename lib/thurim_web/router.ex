defmodule ThurimWeb.Router do
  use ThurimWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :interactive_auth do
    plug ThurimWeb.Plugs.InteractiveAuth
  end

  scope "/_matrix/client", ThurimWeb.Matrix do
    pipe_through :api

    get "/versions", VersionsController, :client
  end

  scope "/_matrix", ThurimWeb.Matrix do
    pipe_through :api

    scope "/client", Client do
      scope "/r0", R0 do
        get "/login", UserController, :index
      end
    end

    scope "/client", Client do
      scope "/r0", R0 do
        pipe_through :interactive_auth

        post "/register", UserController, :create
      end
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: ThurimWeb.Telemetry, ecto_repos: [Thurim.Repo]
    end
  end
end
