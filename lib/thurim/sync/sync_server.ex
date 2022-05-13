defmodule Thurim.Sync.SyncServer do
  use GenServer
  alias Thurim.Presence
  alias Thurim.User
  alias Thurim.Rooms
  alias Thurim.Sync.SyncState

  # Sync state looks like the following:
  # %{
  #   [mx_user_id] => %{[device_id] => [SyncState pid]}
  # }

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = build_state_from_db()
    {:ok, state}
  end

  def add_device(account, device_id) do
    GenServer.cast(__MODULE__, {:add_device, account, device_id})
  end

  def add_user(account, device) do
    GenServer.cast(__MODULE__, {:add_user, account, device})
  end

  def add_room(room, account) do
    GenServer.cast(__MODULE__, {:update_rooms, room, account})
  end

  def build_sync(mx_user_id, device, filter, params) do
    GenServer.call(__MODULE__, {:build_sync, mx_user_id, device, filter, params})
  end

  ###########################
  # Below is genserver impl #
  ###########################

  # handle_cast for :add_device
  def handle_cast({:add_device, account, device_id}, state) do
    {:noreply,
     Map.update!(state, account.localpart, fn devices ->
       Map.put(devices, device_id, default_room_event_state(account))
     end)}
  end

  # handle_cast for :add_user
  def handle_cast({:add_user, account, device}, state) do
    {:noreplay, Map.put(state, account.localpart, %{device.device_id => {Cursor.new(), %{}}})}
  end

  # handle_cast for :update_rooms
  def handle_cast({:update_rooms, room, account}, state) do
    new_state =
      Map.update(state, account.localpart, %{}, fn devices ->
        devices
        |> Enum.map(fn {device_id, {cursor, rooms}} ->
          {device_id,
           {cursor, Map.put(rooms, room.room_id, %{"persistent" => [], "ephemereal" => []})}}
        end)
        |> Enum.into(%{})
      end)

    {:noreply, new_state}
  end

  # handle_call for :build_sync
  def handle_call(
        {:build_sync, mx_user_id, device, filter, params = %{"since" => since}},
        _from,
        state
      )
      when is_nil(filter) and not is_nil(since) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)

    {:reply}
  end

  def handle_call(
        {:build_sync, mx_user_id, device, filter, params = %{"since" => since}},
        _from,
        state
      )
      when not is_nil(since) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)

    {:reply, build_response(state, account)}
  end

  def handle_call({:build_sync, mx_user_id, device, filter, params}, _from, state)
      when is_nil(filter) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)

    reply = build_response(state, mx_user_id, device)

    {:reply, reply, drain_state(state, mx_user_id, device, reply)}
  end

  def handle_call({:build_sync, mx_user_id, device, filter, params}, _from, state) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)

    {:reply, reply, drain_state(state, account, device)}
  end

  defp handle_presence(set_presence, account) do
    if set_presence do
      Presence.set_user_presence(Thurim.User.mx_user_id(account.localpart), set_presence)
    end
  end

  defp new_sync_state(rooms_with_join_type) do
    case SyncState.start_link([]) do
      {:ok, sync_state} ->
        Enum.each(rooms_with_join_type, &SyncState.add_room_with_type(sync_state, &1))
        sync_state

      _ ->
        raise("Failed to start sync state")
    end
  end

  defp build_response(state, account, device) do
    Map.get(state, account.localpart, %{})
    |> Map.fetch!(device.device_id)
    |> SyncState.get()
  end

  defp drain_state(state, mx_user_id, device, reply) do
    Map.update!(state, account.localpart, fn devices ->
      Map.put(
        devices,
        device.device_id,
        {new_cursor,
         rooms
         |> Enum.map(fn {room_id, _events} ->
           {room_id, %{"persistent" => [], "ephemereal" => []}}
         end)
         |> Enum.into(%{})}
      )
    end)
  end

  defp build_state_from_db() do
    mx_user_id = User.mx_user_id(account.localpart)

    User.list_accounts_with_devices()
    |> Enum.map(fn account ->
      {mx_user_id,
       account.devices
       |> map_devices_to_sync_state(mx_user_id)}
      |> Enum.into(%{})
    end)
    |> Enum.each(fn {mx_user_id, devices} -> Enum.each(devicesend) end)
    |> Enum.into(%{})
  end

  defp map_devices_to_sync_state(devices, mx_user_id) do
    devices
    |> Enum.map(fn device ->
      {device.device_id, rooms_with_mx_user_id(mx_user_id) |> new_sync_state()}
    end)
  end

  defp rooms_with_mx_user_id(mx_user_id) do
    Rooms.list_rooms()
    |> Enum.map(fn room ->
      {room,
       User.user_ids_in_room(room)
       |> Enum.filter(fn {user_id, _join_type} -> user_id == mx_user_id end)}
    end)
    |> Enum.map(fn {room, {_user_id, join_type}} -> {room, join_type} end)
  end
end
