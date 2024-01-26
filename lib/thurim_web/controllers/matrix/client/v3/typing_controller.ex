defmodule ThurimWeb.Matrix.Client.V3.TypingController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.Rooms.{RoomMembership, RoomServer}

  def update(
        conn,
        %{"room_id" => room_id, "mx_user_id" => mx_user_id, "typing" => typing} = params
      ) do
    %{sender: sender} = conn.assigns
    timeout = Map.get(params, "timeout")

    with {:sender_matches_mx_user_id, true} <- {:sender_matches_mx_user_id, sender == mx_user_id},
         {:in_room, true} <- {:in_room, RoomMembership.in_room?(sender, room_id)},
         {:typing, true} <- {:typing, typing} do
      RoomServer.start_typing(room_id, mx_user_id, timeout)
      json(conn, %{})
    else
      {:sender_matches_mx_user_id, false} ->
        json_error(conn, :m_forbidden)

      {:in_room, false} ->
        json_error(conn, :m_forbidden)

      {:typing, false} ->
        RoomServer.stop_typing(room_id, mx_user_id)
        json(conn, %{})
    end
  end
end
