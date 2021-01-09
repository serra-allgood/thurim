defmodule ThurimWeb.UserControllerTest do
  use ThurimWeb.ConnCase
  alias Thurim.Devices
  alias Thurim.AccessTokens

  def clear_cache(_context) do
    ThurimWeb.AuthSessionCache.flush()
    Thurim.AccessTokens.AccessTokenCache.flush()
    :ok
  end

  setup :clear_cache

  def create_user(conn, username, password) do
    request = %{
      "auth" => %{
        "session" => get_auth_session(conn),
        "type" => "m.login.dummy"
      },
      "username" => username,
      "password" => password
    }

    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("user-agent", "TEST")
    |> post(Routes.user_path(conn, :create), request)
    |> json_response(200)
  end

  def login_user(conn, username, password) do
    request = %{
      "type" => "m.login.password",
      "identifier" => %{
        "type" => "m.id.user",
        "user" => username
      },
      "password" => password
    }

    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("user-agent", "TEST")
    |> post(Routes.user_path(conn, :login), request)
    |> json_response(200)
  end

  describe "register/available" do
    test "returns false when the username is not available", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)

      request = %{"username" => username}
      response =
        conn
        |> add_basic_headers()
        |> get(Routes.user_path(conn, :available, request))
        |> json_response(200)

      assert %{"available" => false} = response
    end

    test "returns true when the username is available", %{conn: conn} do
      request = %{"username" => "jump_spider"}
      response =
        conn
        |> add_basic_headers()
        |> get(Routes.user_path(conn, :available, request))
        |> json_response(200)

      assert %{"available" => true} = response
    end
  end

  describe "account/password" do
    test "succeeds when authenticated, not logging out if told not to", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)
      %{"access_token" => access_token} = login_user(conn, username, password)

      assert Devices.list_devices(username) |> length() == 2

      request = %{
        "new_password" => "new_password",
        "auth" => %{
          "session" => get_auth_session(conn),
          "type" => "m.login.dummy"
        },
        "logout_devices" => false
      }

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> post(Routes.user_path(conn, :password), request)
      |> json_response(200)

      assert Devices.list_devices(username) |> length() == 2
      assert AccessTokens.list_access_tokens(username) |> length() == 2
    end

    test "succeeds when authenticated, logging out of all other devices", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)
      %{"access_token" => access_token} = login_user(conn, username, password)

      assert Devices.list_devices(username) |> length() == 2

      request = %{
        "new_password" => "new_password",
        "auth" => %{
          "session" => get_auth_session(conn),
          "type" => "m.login.dummy"
        }
      }

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> post(Routes.user_path(conn, :password), request)
      |> json_response(200)

      assert Devices.list_devices(username) |> length() == 1
      assert AccessTokens.list_access_tokens(username) |> length() == 1
    end
  end

  describe "logout/all" do
    test "deletes all devices and access tokens for the account", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)
      %{"access_token" => access_token} = login_user(conn, username, password)

      assert Devices.list_devices(username) |> length() == 2

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> post(Routes.user_path(conn, :logout_all))
      |> json_response(200)

      assert Devices.list_devices(username) |> length() == 0
      assert AccessTokens.list_access_tokens(username) |> length() == 0
    end
  end

  describe "logout" do
    test "deletes the current device and access token", %{conn: conn} do
      username = "jump_spider"
      password = "password"

      %{"access_token" => access_token, "device_id" => device_id} =
        create_user(conn, username, password)

      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("user-agent", "TEST")
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> post(Routes.user_path(conn, :logout))
      |> json_response(200)

      refute Devices.get_by_device_id(device_id, username)
      assert {:error, :unknown_token} = AccessTokens.verify(access_token)
    end
  end

  describe "login" do
    test "fails when user account is not found", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)

      request = %{
        "type" => "m.login.password",
        "identifier" => %{
          "user" => "wrong_user",
          "type" => "m.id.user"
        },
        "password" => password
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :login), request)
        |> json_response(403)

      assert %{"errcode" => "M_FORBIDDEN"} = response
    end

    test "fails when credentials are invalid", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)

      request = %{
        "type" => "m.login.password",
        "identifier" => %{
          "user" => username,
          "type" => "m.id.user"
        },
        "password" => "wrong password"
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :login), request)
        |> json_response(403)

      assert %{"errcode" => "M_FORBIDDEN"} = response
    end

    test "fails when using an unsupported identifier type", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)

      request = %{
        "type" => "m.login.password",
        "identifier" => %{
          "user" => username,
          "type" => "m.id.unsupported"
        },
        "password" => password
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :login), request)
        |> json_response(400)

      assert %{"error" => "Bad login type"} = response
    end

    test "fails when using an unsupported login type", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)

      request = %{
        "type" => "m.login.unsupported",
        "identifier" => %{
          "user" => username,
          "type" => "m.id.user"
        },
        "password" => password
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :login), request)
        |> json_response(400)

      assert %{"error" => "Bad login type"} = response
    end

    test "succeeds when user authenticates with provided device_id", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      %{"device_id" => original_device_id} = create_user(conn, username, password)

      request = %{
        "type" => "m.login.password",
        "identifier" => %{
          "type" => "m.id.user",
          "user" => username
        },
        "password" => password,
        "device_id" => original_device_id
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :login), request)
        |> json_response(200)

      assert %{
               "device_id" => device_id,
               "access_token" => access_token,
               "well_known" => well_known,
               "user_id" => user_id
             } = response

      assert user_id == "@jump_spider:localhost"
      assert device_id == original_device_id
    end

    test "succeeds when user authenticates", %{conn: conn} do
      username = "jump_spider"
      password = "password"
      create_user(conn, username, password)

      request = %{
        "type" => "m.login.password",
        "identifier" => %{
          "type" => "m.id.user",
          "user" => username
        },
        "password" => password
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :login), request)
        |> json_response(200)

      assert %{
               "device_id" => device_id,
               "access_token" => access_token,
               "well_known" => well_known,
               "user_id" => user_id
             } = response

      assert user_id == "@jump_spider:localhost"
    end
  end

  describe "registration" do
    test "fails when username is invalid", %{conn: conn} do
      # Create first user
      request = %{
        "auth" => %{
          "session" => get_auth_session(conn),
          "type" => "m.login.dummy"
        },
        "username" => "@jump_spider",
        "password" => "password"
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :create), request)
        |> json_response(400)

      assert %{"errcode" => errcode, "error" => message} = response
      assert errcode == "M_INVALID_USERNAME"
    end

    test "fails when username already exits", %{conn: conn} do
      username = "jump_spider"
      # Create first user
      request = %{
        "auth" => %{
          "session" => get_auth_session(conn),
          "type" => "m.login.dummy"
        },
        "username" => username,
        "password" => "password"
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :create), request)
        |> json_response(200)

      assert %{"access_token" => access_token, "device_id" => device_id, "user_id" => user_id} =
               response

      assert user_id == "@#{username}:localhost"

      # Create second user with same localpart
      request = %{
        "auth" => %{
          "session" => get_auth_session(conn),
          "type" => "m.login.dummy"
        },
        "username" => username,
        "password" => "password"
      }

      response =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :create), request)
        |> json_response(400)

      assert %{"errcode" => errcode, "error" => message} = response
      assert errcode = "M_USER_IN_USE"
    end

    test "with username and password provided", %{conn: conn} do
      session = get_auth_session(conn)

      request = %{
        "auth" => %{
          "session" => session,
          "type" => "m.login.dummy"
        },
        "username" => "jump_spider",
        "password" => "password"
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :create), request)
        |> json_response(200)

      assert %{"access_token" => access_token, "user_id" => user_id, "device_id" => device_id} =
               response

      assert user_id = "@jump_spider:localhost"
    end

    test "with auto generated values", %{conn: conn} do
      session = get_auth_session(conn)

      request = %{
        "auth" => %{
          "session" => session,
          "type" => "m.login.dummy"
        }
      }

      response =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
        |> post(Routes.user_path(conn, :create), request)
        |> json_response(200)

      assert %{"access_token" => access_token, "user_id" => user_id, "device_id" => device_id} =
               response
    end
  end
end
