defmodule Thurim.Sync.SyncServer do
  use GenServer
  alias Thurim.Presence
  alias Thurim.User
  alias Thurim.Rooms
  alias Thurim.Sync.SyncState
  alias Thurim.Sync.SyncResponse

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

  def add_device(mx_user_id, device_id) do
    GenServer.cast(__MODULE__, {:add_device, mx_user_id, device_id})
  end

  def add_user(mx_user_id, device) do
    GenServer.cast(__MODULE__, {:add_user, mx_user_id, device})
  end

  def add_room(room, mx_user_id) do
    GenServer.cast(__MODULE__, {:add_room, room, mx_user_id})
  end

  def build_sync(mx_user_id, device, filter, timeout, params) do
    GenServer.call(
      __MODULE__,
      {:build_sync, mx_user_id, device, filter, timeout, params},
      timeout + 5000
    )
  end

  ###########################
  # Below is genserver impl #
  ###########################

  # handle_cast for :add_device
  def handle_cast({:add_device, mx_user_id, device_id}, state) do
    new_state =
      Map.put(
        state,
        mx_user_id,
        Map.fetch!(state, mx_user_id)
        |> Map.put(device_id, new_sync_state(rooms_with_mx_user_id(mx_user_id), mx_user_id))
      )

    {:noreply, new_state}
  end

  # handle_cast for :add_user
  def handle_cast({:add_user, mx_user_id, device}, state) do
    new_state =
      Map.put(state, mx_user_id, %{
        device.device_id => new_sync_state(rooms_with_mx_user_id(mx_user_id), mx_user_id)
      })

    {:noreply, new_state}
  end

  # handle_cast for :add_room
  def handle_cast({:add_room, room, mx_user_id}, state) do
    Map.fetch!(state, mx_user_id)
    |> Enum.each(fn {_device_id, sync_state} ->
      SyncState.add_room_with_type(sync_state, mx_user_id, {room, "join"})
    end)

    {:noreply, state}
  end

  # handle_call for :build_sync
  # TODO - implement filtering
  def handle_call(
        {:build_sync, mx_user_id, device, filter, timeout, %{"since" => since} = params},
        from,
        state
      )
      when is_nil(filter) and not is_nil(since) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    cursor = SyncState.get_cursor(sync_state)

    {cursor, reply} =
      if cursor != since do
        SyncState.get_since(sync_state, since, full_state)
      else
        SyncState.get(sync_state, full_state)
      end

    if SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout, params}
      )

      {:noreply, state}
    else
      {:reply, reply, drain_state(state, mx_user_id, device, reply, cursor)}
    end
  end

  def handle_call(
        {:build_sync, mx_user_id, device, filter, timeout, params = %{"since" => since}},
        from,
        state
      )
      when not is_nil(since) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    cursor = SyncState.get_cursor(sync_state)

    {cursor, reply} =
      if cursor != since do
        SyncState.get_since(sync_state, since, full_state)
      else
        SyncState.get(sync_state, full_state)
      end

    if SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout, params}
      )

      {:noreply, state}
    else
      {:reply, reply, drain_state(state, mx_user_id, device, reply, cursor)}
    end
  end

  # TODO - implement filtering
  def handle_call({:build_sync, mx_user_id, device, filter, timeout, params}, from, state)
      when is_nil(filter) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    {cursor, reply} = SyncState.get(sync_state, full_state)

    if SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout, params}
      )

      {:noreply, state}
    else
      {:reply, reply, drain_state(state, mx_user_id, device, reply, cursor)}
    end
  end

  def handle_call({:build_sync, mx_user_id, device, _filter, timeout, params}, from, state) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    {cursor, reply} = SyncState.get(sync_state, full_state)

    if SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, _filter, timeout, params}
      )

      {:noreply, state}
    else
      {:reply, reply, drain_state(state, mx_user_id, device, reply, cursor)}
    end
  end

  # TODO - implement filtering
  def handle_info({:check_sync, from, mx_user_id, device, filter, timeout, params}, state) do
    since = Map.get(params, "since", nil)
    full_state = Map.get(params, "full_state", false)

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    {cursor, reply} = SyncState.get(sync_state, full_state)

    if SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout - 1000, params}
      )

      {:noreply, state}
    else
      GenServer.reply(from, reply)

      {:noreply, drain_state(state, mx_user_id, device, reply, cursor)}
    end

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp handle_presence(set_presence, mx_user_id) do
    if set_presence do
      Presence.set_user_presence(mx_user_id, set_presence)
    end
  end

  defp new_sync_state(rooms_with_join_type, sender) do
    case SyncState.start_link([]) do
      {:ok, sync_state} ->
        Enum.each(rooms_with_join_type, &SyncState.add_room_with_type(sync_state, sender, &1))
        sync_state

      _ ->
        raise("Failed to start sync state")
    end
  end

  defp drain_state(state, mx_user_id, device, reply, cursor) do
    Map.fetch!(state, mx_user_id)
    |> Map.fetch!(device.device_id)
    |> SyncState.drain(cursor)

    state
  end

  defp build_state_from_db() do
    User.list_accounts_with_devices()
    |> Enum.map(fn account ->
      mx_user_id = User.mx_user_id(account.localpart)

      {mx_user_id,
       account.devices
       |> map_devices_to_sync_state(mx_user_id)}
    end)
    |> Enum.into(%{})
  end

  defp map_devices_to_sync_state(devices, mx_user_id) do
    devices
    |> Enum.map(fn device ->
      {device.device_id, rooms_with_mx_user_id(mx_user_id) |> new_sync_state(mx_user_id)}
    end)
    |> Enum.into(%{})
  end

  defp rooms_with_mx_user_id(mx_user_id) do
    Rooms.list_rooms()
    |> Enum.map(fn room ->
      {room,
       User.user_ids_in_room(room)
       |> Enum.filter(fn {user_id, _join_type} -> user_id == mx_user_id end)
       |> List.first()}
    end)
    |> Enum.map(fn {room, {_user_id, join_type}} -> {room, join_type} end)
  end
end
