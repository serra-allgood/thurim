defmodule Thurim.RoomServer do
  use GenServer
  alias Thurim.Rooms
  alias Thurim.Events

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = build_state_from_db()
    {:ok, state}
  end

  def add_room(room) do
    GenServer.cast(__MODULE__, {:add_room, room})
  end

  def add_user_to_room(room, sender) do
    GenServer.cast(__MODULE__, {:add_user, room, sender})
  end

  def handle_cast({:add_room, room}, state) do
    {:noreply, Map.put(state, room.room_id, [])}
  end

  def handle_cast({:add_user, room, sender}, state) do
    {:noreply, Map.update(state, room.room_id, [], fn users -> users ++ [sender] end)}
  end

  defp build_state_from_db() do
    Rooms.list_rooms()
    |> Enum.reduce(%{}, fn room, state ->
      Map.put(state, room.room_id, users_in_room(room.room_id))
    end)
  end

  defp users_in_room(room_id) do
    Events.users_in_room(room_id)
  end
end
