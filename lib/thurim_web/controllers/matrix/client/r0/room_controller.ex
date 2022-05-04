defmodule ThurimWeb.Matrix.Client.R0.RoomController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.User
  alias Thurim.Rooms
  alias Thurim.RoomServer

  # Event shape:
  # {
  #   initial_state: Event[],
  #   create_content: "extra keys to be added to the m.room.create event",
  #   preset: private_chat | trusted_private_chat | public_chat,
  #   name?: string
  # }
  def create(conn, params) do
    sender = Map.fetch!(conn.assigns, "sender")

    result =
      Map.put(params, "sender", sender)
      |> Rooms.create_room()

    case result do
      {:ok, room} ->
        RoomServer.add_room(room)
        RoomServer.add_user_to_room(room, sender)
        json(conn, %{room_id: room.room_id})

      {:error, error} ->
        json_error(conn, error)
    end
  end
end
