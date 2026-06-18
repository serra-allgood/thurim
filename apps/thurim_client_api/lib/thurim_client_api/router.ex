defmodule ThurimClientApi.Router do
  use ThurimApiHelpers.ThurimRouter

  pipeline :maybe_interactive_auth do
    plug ThurimApiHelpers.Plugs.MaybeInteractiveAuth
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
    pipe_through :maybe_interactive_auth

    post "/delete_devices", DeviceController, :delete_devices
    delete "/devices/:device_id", DeviceController, :delete

    post "/keys/device_signing/upload", CrossSigningKeyController, :create_keys
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
    get "/login/sso/redirect", SessionController, :sso_redirect
    get "/login/sso/redirect/:idp_id", SessionController, :sso_redirect
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

    get "/admin/lock/:user_id", AdminController, :show_lock
    put "/admin/lock/:user_id", AdminController, :update_lock
    get "/admin/suspend/:user_id", AdminController, :show_suspend
    put "/admin/suspend/:user_id", AdminController, :update_suspend
    get "/admin/whois/:user_id", AdminController, :whois

    get "/capabilities", CapabilityController, :index

    post "/keys/signatures/upload", CrossSigningKeyController, :create_signatures

    get "/devices", DeviceController, :index
    get "/devices/:device_id", DeviceController, :show
    put "/devices/:device_id", DeviceController, :update

    put "/directory/list/room/:room_id", DirectoryController, :update_visibility
    delete "/directory/room/:room_alias", DirectoryController, :delete
    put "/directory/room/:room_alias", DirectoryController, :update

    post "/user/:user_id/filter", FilterController, :create
    get "/user/:user_id/filter/:filter_id", FilterController, :show

    get "/keys/changes", KeyController, :changes
    post "/keys/claim", KeyController, :claim
    post "/keys/query", KeyController, :query
    post "/keys/upload", KeyController, :create

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

    get "/presence/:user_id/status", PresenceController, :show
    put "/presence/:user_id/status", PresenceController, :update
    put "/rooms/:room_id/typing/:user_id", PresenceController, :typing

    get "/pushers", PusherController, :index
    get "/pushers/set", PusherController, :set

    get "/pushrules", PushRuleController, :index
    get "/pushrules/global", PushRuleController, :global
    delete "/pushrules/global/:kind/:rule_id", PushRuleController, :delete
    get "/pushrules/global/:kind/:rule_id", PushRuleController, :show
    put "/pushrules/global/:kind/:rule_id", PushRuleController, :upsert
    get "/pushrules/global/:kind/:rule_id/enabled", PushRuleController, :show_enabled
    put "/pushrules/global/:kind/:rule_id/enabled", PushRuleController, :update_enabled

    get "/notifications", NotificationController, :index

    post "/rooms/:room_id/report", ReportController, :report_room
    post "/rooms/:room_id/report/:event_id", ReportController, :report_event
    post "/users/:user_id/report", ReportController, :report_user

    post "/createRoom", RoomController, :create
    get "/events", RoomController, :listen
    get "/rooms/:room_id/aliases", RoomController, :aliases
    get "/rooms/:room_id/context/:event_id", RoomController, :context
    get "/rooms/:room_id/event/:event_id", RoomController, :event
    get "/rooms/:room_id/hierarchy", RoomController, :hierarchy
    get "/rooms/:room_id/initialSync", RoomController, :initial_sync
    get "/rooms/:room_id/members", RoomController, :members
    get "/rooms/:room_id/messages", RoomController, :messages
    post "/rooms/:room_id/read_markers", RoomController, :read_markers
    post "/rooms/:room_id/receipt/:receipt_type/:event_id", RoomController, :update_receipt_type
    put "/rooms/:room_id/redact/:event_id/:txn_id", RoomController, :redact
    put "/rooms/:room_id/send/:event_type/:txn_id", RoomController, :send
    get "/rooms/:room_id/state", RoomController, :current_state
    get "/rooms/:room_id/state/:event_type/:state_key", RoomController, :state_event
    put "/rooms/:room_id/state/:event_type/:state_key", RoomController, :upsert_state_event
    get "/rooms/:room_id/threads", RoomController, :threads
    post "/rooms/:room_id/upgrade", RoomController, :upgrade

    delete "/room_keys/keys", RoomKeyController, :batch_delete
    get "/room_keys/keys", RoomKeyController, :index
    put "/room_keys/keys", RoomKeyController, :batch_create
    delete "/room_keys/keys/:room_id", RoomKeyController, :delete
    get "/room_keys/keys/:room_id", RoomKeyController, :show
    put "/room_keys/keys/:room_id", RoomKeyController, :create
    delete "/room_keys/keys/:room_id/:session_id", RoomKeyController, :delete_session_key
    get "/room_keys/keys/:room_id/:session_id", RoomKeyController, :show_session_key
    put "/room_keys/keys/:room_id/:session_id", RoomKeyController, :create_session_key
    get "/room_keys/version", RoomKeyController, :show_latest_version
    post "/room_keys/version", RoomKeyController, :create_version
    delete "/room_keys/version/:version", RoomKeyController, :delete_version
    get "/room_keys/version/:version", RoomKeyController, :show_version
    put "/room_keys/version/:version", RoomKeyController, :update_version

    get "/user/:user_id/rooms/:room_id/tags", RoomTagController, :show
    delete "/user/:user_id/rooms/:room_id/tags/:tag", RoomTagController, :delete
    put "/user/:user_id/rooms/:room_id/tags/:tag", RoomTagController, :create

    post "/search", SearchController, :index

    post "/logout/all", SessionController, :logout_all
    post "/logout", SessionController, :logout

    put "/sendToDevice/:event_type/:txn_id", SendToDeviceController, :create

    get "/sync", SyncController, :sync

    get "/voip/turnServer", TurnServer, :show

    delete "/profile/:user_id/:key_name", UserController, :delete_profile_field
    put "/profile/:user_id/:key_name", UserController, :update_profile_field
    get "/user/:user_id/account_data/:type", UserController, :account_data
    put "/user/:user_id/account_data/:type", UserController, :update_account_data
    post "/user/:user_id/opendid/request_token", UserController, :openid_token
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
