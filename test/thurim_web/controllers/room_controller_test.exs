defmodule ThurimWeb.RoomControllerTest do
  use ThurimWeb.ConnCase

  def clear_cache(_context) do
    ThurimWeb.AuthSessionCache.flush()
    Thurim.AccessTokens.AccessTokenCache.flush()
    :ok
  end

  setup :clear_cache

  describe "POST /createRoom" do
    test "returns a 200 response", %{conn: conn} do
      %{"access_token" => access_token} = create_user(conn, "jump_spider", "password")

      conn
      |> add_basic_headers()
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> post(Routes.room_path(conn, :create))
      |> json_response(200)
    end

    test "returns a room_id", %{conn: conn} do
      %{"access_token" => access_token} = create_user(conn, "jump_spider", "password")

      response =
        conn
        |> add_basic_headers()
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(Routes.room_path(conn, :create))
        |> json_response(200)

      assert Map.has_key?(response, "room_id")
    end
  end
end
