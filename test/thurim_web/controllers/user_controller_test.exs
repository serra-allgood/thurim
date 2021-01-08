defmodule ThurimWeb.UserControllerTest do
  use ThurimWeb.ConnCase

  def clear_cache(_context) do
    ThurimWeb.AuthSessionCache.flush()
    Thurim.AccessTokens.AccessTokenCache.flush()
    :ok
  end

  setup :clear_cache

  describe "registration" do
    test "register/2 fails when username already exits", %{conn: conn} do
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
        |> post(Routes.user_path(conn, :create, request))
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
        |> post(Routes.user_path(conn, :create, request))
        |> json_response(200)

      assert %{"access_token" => access_token, "user_id" => user_id, "device_id" => device_id} =
               response
    end
  end
end
