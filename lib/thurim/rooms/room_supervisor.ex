defmodule Thurim.Rooms.RoomSupervisor do
  use DynamicSupervisor
  alias Thurim.{Rooms, Rooms.RoomServer}

  def start_link(_options) do
    with {:ok, pid} <- DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__),
         {:ok, _} <- DynamicSupervisor.start_child(__MODULE__, {Task, &hydrate_rooms/0}) do
      {:ok, pid}
    end
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_room(room_id) do
    spec = %{id: RoomServer, start: {RoomServer, :start_link, [room_id]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def hydrate_rooms() do
    Rooms.list_rooms()
    |> Enum.each(&start_room(&1.room_id))
  end
end
