defmodule ThurimClientApi.RoomController do
  use ThurimClientApi, :controller
  alias ThurimCore.{MatrixConfig, Rooms, Rooms.Room}

  def create(conn, params) do
    current_user = Map.fetch!(conn.assigns, :current_user)

    %{
      "creator" => current_user.user_id,
      "sender" => current_user.user_id,
      "room_version" => Map.get(params, "room_version", MatrixConfig.default_room_version()),
      "creation_content" => Map.get(params, "creation_content")
    }
    |> then(&Map.merge(params, &1))
    |> Rooms.create_room()
    |> case do
      {:ok, %Room{} = room} ->
        json(conn, %{room_id: room.room_id})

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errcode: "M_BAD_JSON", error: "There was a problem in the request payload."})
    end
  end
end
