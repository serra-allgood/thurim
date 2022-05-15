defmodule ThurimWeb.Matrix.Client.R0.RoomController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.Sync.SyncServer
  alias Thurim.Rooms
  alias Thurim.Events
  alias Thurim.User

  # Event shape:
  # {
  #   initial_state: Event[],
  #   create_content: "extra keys to be added to the m.room.create event",
  #   preset: private_chat | trusted_private_chat | public_chat,
  #   name?: string
  # }
  def create(conn, params) do
    sender = Map.fetch!(conn.assigns, :sender)

    result =
      Map.put(params, "sender", sender)
      |> Rooms.create_room()

    case result do
      {:ok, room} ->
        SyncServer.add_room(room, sender)
        json(conn, %{room_id: room["room_id"]})

      {:error, error} ->
        json_error(conn, error)
    end
  end

  def get_event(conn, %{"room_id" => room_id, "event_id" => event_id} = _params) do
    case Events.get_by(room_id: room_id, event_id: event_id) do
      nil ->
        json_error(conn, :m_not_found)

      event when is_nil(event.state_key) ->
        json(conn, %{
          content: event.content,
          event_id: event.event_id,
          origin_server_ts: event.origin_server_ts,
          room_id: event.room_id,
          sender: event.sender,
          type: event.type
        })

      event ->
        json(conn, %{
          content: event.content,
          event_id: event.event_id,
          origin_server_ts: event.origin_server_ts,
          room_id: event.room_id,
          sender: event.sender,
          type: event.type,
          state_key: event.state_key
        })
    end
  end

  def joined_members(conn, %{"room_id" => room_id} = _params) do
    sender = Map.fetch!(conn.assigns, :sender)

    if SyncServer.user_in_room?(sender, room_id) do
      response = User.joined_user_ids_in_room(room_id)
      json(conn, %{"joined" => response})
    else
      json_error(conn, :m_forbidden)
    end
  end
end
