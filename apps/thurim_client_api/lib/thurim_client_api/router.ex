defmodule ThurimClientApi.Router do
  use ThurimClientApi, :router

  pipeline :access_token do
    plug ThurimApiHelpers.Plugs.ExtractAccessToken
    plug ThurimApiHelpers.Plugs.RequireAccessToken
  end

  pipeline :interactive_auth do
    plug ThurimApiHelpers.Plugs.InteractiveAuth
  end

  # Routes are sorted first by controller name, then by path
  scope "/v1", ThurimClientApi do
    pipe_through :access_token

    get "/room_summary/:room_id_or_alias", RoomController, :summary
    get "/rooms/:room_id/timestamp_to_event", RoomController, :timestamp_to_event
    get "/rooms/:room_id/relations/:event_id", RoomController, :relations
    get "/rooms/:room_id/relations/:event_id/:rel_type", RoomController, :relations
    get "/rooms/:room_id/relations/:event_id/:rel_type/:event_type", RoomController, :relations
  end

  scope "/v1", ThurimClientApi do
    get "/auth_metadata", SessionController, :auth_metadata

    pipe_through :interactive_auth
    post "/login/get_token", SessionController, :get_token
  end

  scope "/v3", ThurimClientApi do
    pipe_through :interactive_auth

    post "/account/deactivate", AccountController, :deactivate
    post "/account/password", AccountController, :change_password
    post "/account/3pid/add", AccountController, :add_threepid

    post "/register", RegistrationController, :register
  end

  scope "/v3", ThurimClientApi do
    # Public
    post "/account/3pid/email/requestToken", AccountController, :threepid_email
    post "/account/3pid/msisdn/requestToken", AccountController, :threepid_msisdn
    post "/account/password/email/requestToken", AccountController, :email
    post "/account/password/msisdn/requestToken", AccountController, :msisdn

    get "/directory/list/room/:room_id", DirectoryController, :visibility
    get "/directory/room/:room_alias", DirectoryController, :show
    get "/publicRooms", DirectoryController, :index
    post "/publicRooms", DirectoryController, :index

    get "/login", SessionController, :login_types
    post "/login", SessionController, :login
    post "/refresh", SessionController, :refresh

    get "/register/available", RegistrationController, :available
    post "/register/email/requestToken", RegistrationController, :email
    post "/register/msisdn/requestToken", RegistrationController, :msisdn

    get "/profile/:user_id", UserController, :show
    get "/profile/:user_id/:key_name", UserController, :show

    # Authenticated
    pipe_through :access_token
    get "/account/3pid", AccountController, :threepid
    post "/account/3pid/bind", AccountController, :bind_threepid
    delete "/account/3pid/delete", AccountController, :delete_threepid
    post "/account/3pid/unbind", AccountController, :unbind_threepid
    get "/account/whoami", AccountController, :whoami

    get "/capabilities", CapabilityController, :index

    put "/directory/list/room/:room_id", DirectoryController, :update_visibility
    delete "/directory/room/:room_alias", DirectoryController, :delete
    put "/directory/room/:room_alias", DirectoryController, :update

    post "/user/:user_id/filter", FilterController, :create
    get "/user/:user_id/filter/:filter_id", FilterController, :show

    post "/join/:room_id_or_alias", MembershipController, :join
    post "/knock/:room_id_or_alias", MembershipController, :knock
    get "/joined_rooms", MembershipController, :joined_rooms
    post "/room/:room_id/ban", MembershipController, :ban
    post "/rooms/:room_id/forget", MembershipController, :forget
    post "/rooms/:room_id/invite", MembershipController, :invite
    post "/rooms/:room_id/join", MembershipController, :join
    post "/room/:room_id/kick", MembershipController, :kick
    post "/rooms/:room_id/leave", MembershipController, :leave
    get "/rooms/:room_id/joined_members", MembershipController, :joined_members
    post "/rooms/:room_id/unban", MembershipController, :unban

    post "/createRoom", RoomController, :create
    get "/rooms/:room_id/aliases", RoomController, :aliases
    get "/rooms/:room_id/event/:event_id", RoomController, :event
    get "/rooms/:room_id/initialSync", RoomController, :initial_sync
    get "/rooms/:room_id/members", RoomController, :members
    get "/rooms/:room_id/messages", RoomController, :messages
    put "/rooms/:room_id/redact/:event_id/:txn_id", RoomController, :redact
    put "/rooms/:room_id/send/:event_type/:txn_id", RoomController, :send
    get "/rooms/:room_id/state", RoomController, :current_state
    get "/rooms/:room_id/state/:event_type/:state_key", RoomController, :state_event
    put "/rooms/:room_id/state/:event_type/:state_key", RoomController, :upsert_state_event

    post "/logout/all", SessionController, :logout_all
    post "/logout", SessionController, :logout

    get "/sync", SyncController, :sync

    delete "/profile/:user_id/:key_name", UserController, :delete_profile_field
    put "/profile/:user_id/:key_name", UserController, :update_profile_field
    get "/user/:user_id/account_data/:type", UserController, :account_data
    put "/user/:user_id/account_data/:type", UserController, :update_account_data
    get "/user/:user_id/rooms/:room_id/account_data/:type", UserController, :room_account_data

    put "/user/:user_id/rooms/:room_id/account_data/:type",
        UserController,
        :update_room_account_data

    post "/user_directory/search", UserController, :search
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
