defmodule ThurimWeb.PresenceControllerTest do
  use ThurimWeb.ConnCase

  alias Thurim.Presence

  def clear_cache(_context) do
    ThurimWeb.AuthSessionCache.flush()
    Thurim.AccessTokens.AccessTokenCache.flush()
    :ok
  end

  setup :clear_cache

  describe "PUT /presence/{user_id}/status" do
    test "it returns a 200 response", %{conn: conn} do
      localpart = "jump_spider"
      %{"access_token" => access_token} = create_user(conn, localpart, "password")

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> put(Routes.presence_path(conn, :update, Thurim.User.mx_user_id(localpart)))
      |> json_response(200)
    end

    test "can only update logged in user's presence", %{conn: conn} do
      localpart = "jump_spider"
      %{"access_token" => access_token} = create_user(conn, localpart, "password")

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> put(Routes.presence_path(conn, :update, Thurim.User.mx_user_id("other_user")))
      |> json_response(403)
    end

    test "updates Presence with params", %{conn: conn} do
      %{"access_token" => access_token} = create_user(conn, "jump_spider", "password")

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> put(Routes.presence_path(conn, :update, Thurim.User.mx_user_id("jump_spider")), %{"presence" => "online", "status_msg" => "I am here"})
      |> json_response(200)

      %{presence: presence, status_msg: status_msg} = Presence.get_user_presence(Thurim.User.mx_user_id("jump_spider"))
      assert presence == "online"
      assert status_msg == "I am here"
    end
  end
end
