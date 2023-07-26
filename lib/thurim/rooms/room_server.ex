defmodule Thurim.Rooms.RoomServer do
  use GenServer

  def via_tuple(room_id), do: {:via, Registry, {Registry.Room, room_id}}

  def start_link(room_id) when is_binary(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  @impl true
  def init(room_id) do
    {:ok, %{room_id: room_id, listeners: MapSet.new()}}
  end

  def register_listener(room_id, pid) do
    GenServer.cast(via_tuple(room_id), {:register_listener, pid})
  end

  def unregister_listener(room_id, pid) do
    GenServer.cast(via_tuple(room_id), {:unregister_listener, pid})
  end

  def notify_listeners(room_id) do
    GenServer.cast(via_tuple(room_id), :notify_listeners)
  end

  @impl true
  def handle_cast({:register_listener, pid}, state) do
    {:noreply, %{state | listeners: MapSet.put(state.listeners, pid)}}
  end

  @impl true
  def handle_cast({:unregister_listener, pid}, state) do
    {:noreply, %{state | listeners: MapSet.delete(state.listeners, pid)}}
  end

  @impl true
  def handle_cast(:notify_listeners, state) do
    Enum.each(state.listeners, fn pid -> send(pid, {:room_update, state.room_id}) end)
    {:noreply, state}
  end
end
