defmodule Thurim.Rooms.RoomServer do
  use GenServer
  alias Thurim.Events

  def via_tuple(room_id), do: {:via, Registry, {Registry.Room, room_id}}

  def start_link(room_id) when is_binary(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  @impl true
  def init(room_id) do
    room_events = Events.for_room(room_id)
    {:ok, room_events}
  end
end
