defmodule ThurimWeb.Router do
  use ThurimWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :interactive_auth do
    plug ThurimWeb.Plugs.InteractiveAuth
  end

  pipeline :access_token do
    plug ThurimWeb.Plugs.ExtractAccessToken
    plug ThurimWeb.Plugs.RequireAccessToken
  end

  scope "/.well-known/matrix", ThurimWeb.Matrix do
    pipe_through :api

    get "/client", WellKnownController, :client
  end

  scope "/_matrix/client", ThurimWeb.Matrix do
    pipe_through :api

    get "/versions", VersionsController, :client
  end

  scope "/_matrix", ThurimWeb.Matrix do
    pipe_through :api

    scope "/client", Client do
      scope "/v3", V3 do
        get "/login", UserController, :index
        post "/login", UserController, :login
        get "/register/available", UserController, :available
        get "/publicRooms", RoomController, :index
      end

      scope "/r0", V3 do
        get "/login", UserController, :index
        post "/login", UserController, :login
        get "/register/available", UserController, :available
        get "/directory/room/:room_alias", DirectoryController, :room_alias
        get "/publicRooms", RoomController, :index
      end
    end

    scope "/client", Client do
      scope "/v3", V3 do
        pipe_through :interactive_auth

        post "/register", UserController, :create
      end

      scope "/r0", V3 do
        pipe_through :interactive_auth

        post "/register", UserController, :create
      end
    end

    scope "/client", Client do
      scope "/v3", V3 do
        pipe_through :access_token

        post "/logout", UserController, :logout
        post "/logout/all", UserController, :logout_all
        get "/account/whoami", UserController, :whoami
        get "/pushrules", UserController, :push_rules

        post "/user/:user_id/filter", FilterController, :create
        get "/user/:user_id/filter/:filter_id", FilterController, :show

        get "/presence/:user_id/status", PresenceController, :show
        put "/presence/:user_id/status", PresenceController, :update

        get "/sync", SyncController, :index

        post "/createRoom", RoomController, :create
        get "/rooms/:room_id/event/:event_id", RoomController, :get_event
        get "/rooms/:room_id/joined_members", RoomController, :joined_members
        get "/rooms/:room_id/members", RoomController, :members
        get "/rooms/:room_id/state", RoomController, :state
        get "/rooms/:room_id/state/:event_type/:state_key", RoomController, :state_event
        put "/rooms/:room_id/state/:event_type/:state_key", RoomController, :create_state_event
        put "/rooms/:room_id/send/:event_type/:txn_id", RoomController, :send_message
        put "/rooms/:room_id/redact/:event_id/:txn_id", RoomController, :create_redaction
        get "/rooms/:room_id/messages", RoomController, :messages
        post "/publicRooms", RoomController, :public_rooms
        post "/join/:room_id_or_alias", RoomController, :join
        post "/rooms/:room_id/join", RoomController, :join
        post "/rooms/:room_id/leave", RoomController, :leave

        put "/rooms/:room_id/typing/:mx_user_id", TypingController, :update

        post "/rooms/:room_id/receipt/:receipt_type/:event_id", ReceiptController, :create
        post "/rooms/:room_id/read_markers", ReceiptController, :fully_read

        post "/keys/query", KeysController, :query
        post "/keys/upload", KeysController, :upload

        get "/directory/room/:room_alias", DirectoryController, :room_alias
      end

      scope "/r0", V3 do
        pipe_through :access_token

        post "/logout", UserController, :logout
        post "/logout/all", UserController, :logout_all
        get "/account/whoami", UserController, :whoami
        get "/pushrules", UserController, :push_rules

        post "/user/:user_id/filter", FilterController, :create
        get "/user/:user_id/filter/:filter_id", FilterController, :show

        get "/presence/:user_id/status", PresenceController, :show
        put "/presence/:user_id/status", PresenceController, :update

        get "/sync", SyncController, :index

        post "/createRoom", RoomController, :create
        get "/rooms/:room_id/event/:event_id", RoomController, :get_event
        get "/rooms/:room_id/joined_members", RoomController, :joined_members
        get "/rooms/:room_id/members", RoomController, :members
        get "/rooms/:room_id/state", RoomController, :state
        get "/rooms/:room_id/state/:event_type/:state_key", RoomController, :state_event
        put "/rooms/:room_id/state/:event_type/:state_key", RoomController, :create_state_event
        put "/rooms/:room_id/send/:event_type/:txn_id", RoomController, :send_message
        put "/rooms/:room_id/redact/:event_id/:txn_id", RoomController, :create_redaction
        get "/rooms/:room_id/messages", RoomController, :messages
        post "/publicRooms", RoomController, :public_rooms
        post "/join/:room_id_or_alias", RoomController, :join
        post "/rooms/:room_id/join", RoomController, :join
        post "/rooms/:room_id/leave", RoomController, :leave

        put "/rooms/:room_id/typing/:mx_user_id", TypingController, :update

        post "/rooms/:room_id/receipt/:receipt_type/:event_id", ReceiptController, :create
        post "/rooms/:room_id/read_markers", ReceiptController, :fully_read

        post "/keys/query", KeysController, :query
        post "/keys/upload", KeysController, :upload
      end
    end

    scope "/client", Client do
      scope "/v3", V3 do
        pipe_through [:interactive_auth, :access_token]

        post "/account/password", UserController, :password
      end

      scope "/r0", V3 do
        pipe_through [:interactive_auth, :access_token]

        post "/account/password", UserController, :password
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
