defmodule Thurim.Rooms.RoomServer do
  use GenServer
  alias Thurim.Rooms

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def list_rooms() do
    GenServer.call(__MODULE__, :list_rooms)
  end

  def create_room(attrs \\ %{}) do
    GenServer.call(__MODULE__, {:create_room, attrs})
  end

  @impl true
  def init(_) do
    state = Rooms.list_rooms()
    {:ok, state}
  end

  @impl true
  def handle_call(:list_rooms, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:create_room, attrs}, _from, state) do
    case Rooms.create_room(attrs) do
      {:ok, %{room: room} = _changes} ->
        state = [room | state]
        {:reply, {:ok, room.room_id}, state}

      {:error, _name, changeset, _changes} ->
        {:reply, {:error, changeset}, state}
    end
  end
end
