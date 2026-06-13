defmodule ThurimCore.Rooms.RoomSupervisor do
  use DynamicSupervisor

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_room(room_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {ThurimCore.Rooms.RoomServer, room_id}
    )
  end
end
