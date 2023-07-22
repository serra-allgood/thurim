defmodule Thurim.Rooms.RoomSupervisor do
  use DynamicSupervisor
  alias Thurim.{Rooms, Rooms.RoomServer}

  def start_link(_options) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Rooms.list_rooms() |> Enum.map(fn room -> room.room_id end) |> Enum.each(&start_room/1)
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_room(room_id) do
    spec = %{id: RoomServer, start: {RoomServer, :start_link, [room_id]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
