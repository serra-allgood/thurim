defmodule Thurim.Rooms.RoomServer do
  use GenServer

  alias Thurim.Presence.PresenceServer

  def via_tuple(room_id), do: {:via, Registry, {Registry.Room, room_id}}

  def start_link(room_id) when is_binary(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  def exists?(room_id) do
    !(Registry.lookup(Registry.Room, room_id) |> Enum.empty?())
  end

  @impl true
  def init(room_id) do
    {:ok,
     %{
       room_id: room_id,
       listeners: MapSet.new(),
       typing: MapSet.new(),
       typing_timeout_refs: %{},
       latest_typing_update: 0
     }}
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

  def start_typing(room_id, mx_user_id, timeout) when is_nil(timeout) do
    GenServer.cast(via_tuple(room_id), {:start_typing, mx_user_id, nil})
    notify_listeners(room_id)
  end

  def start_typing(room_id, mx_user_id, timeout) do
    {:ok, tref} = :timer.apply_after(timeout, __MODULE__, :stop_typing, [room_id, mx_user_id])
    GenServer.cast(via_tuple(room_id), {:start_typing, mx_user_id, tref})
    notify_listeners(room_id)
  end

  def stop_typing(room_id, mx_user_id) do
    GenServer.cast(via_tuple(room_id), {:stop_typing, mx_user_id})
    notify_listeners(room_id)
  end

  def get_typing(room_id) do
    GenServer.call(via_tuple(room_id), :get_typing)
  end

  @impl true
  def handle_call(:get_typing, _from, state) do
    {:reply, %{latest_update: state.latest_typing_update, typings: MapSet.to_list(state.typing)},
     state}
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
    {:noreply, %{state | listeners: MapSet.new()}}
  end

  @impl true
  def handle_cast({:start_typing, mx_user_id, tref}, %{typing_timeout_refs: refs} = state) do
    tref_for_user = Map.get(refs, mx_user_id)
    if !is_nil(tref_for_user), do: :timer.cancel(tref_for_user)

    PresenceServer.set_edu_count(1)
    latest_typing_update = PresenceServer.get_edu_count()

    {:noreply,
     %{
       state
       | typing: MapSet.put(state.typing, mx_user_id),
         typing_timeout_refs: Map.put(state.typing_timeout_refs, mx_user_id, tref),
         latest_typing_update: latest_typing_update
     }}
  end

  @impl true
  def handle_cast({:stop_typing, mx_user_id}, state) do
    PresenceServer.set_edu_count(1)
    latest_typing_update = PresenceServer.get_edu_count()

    {:noreply,
     %{
       state
       | typing: MapSet.delete(state.typing, mx_user_id),
         latest_typing_update: latest_typing_update
     }}
  end
end
