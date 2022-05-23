defmodule Thurim.Sync.SyncServer do
  use GenServer
  alias Thurim.Presence
  alias Thurim.User
  alias Thurim.Rooms
  alias Thurim.Events
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

  def remove_device(mx_user_id, device) do
    GenServer.cast(__MODULE__, {:remove_device, mx_user_id, device})
  end

  def append_event(mx_user_id, device, room_id, event) do
    GenServer.cast(__MODULE__, {:append_event, mx_user_id, device, room_id, event})
  end

  def append_state_event(mx_user_id, device, room_id, event) do
    GenServer.cast(__MODULE__, {:append_state_event, mx_user_id, device, room_id, event})
  end

  def user_in_room?(mx_user_id, room_id) do
    GenServer.call(__MODULE__, {:user_in_room?, mx_user_id, room_id})
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

  # handle_cast for :remove_device
  def handle_cast({:remove_device, mx_user_id, device}, state) do
    Map.fetch!(state, mx_user_id)
    |> Map.fetch!(device.device_id)
    |> SyncState.stop()

    state =
      Map.update!(state, mx_user_id, fn devices -> Map.drop(devices, [device.device_id]) end)

    {:noreply, state}
  end

  # handle_cast for :append_event
  def handle_cast({:append_event, mx_user_id, device, room_id, event}, state) do
    Map.fetch!(state, mx_user_id)
    |> Enum.filter(fn {device_id, _pid} -> device_id != device.device_id end)
    |> Enum.each(fn {_device_id, pid} -> SyncState.append_timeline(pid, room_id, event) end)

    {:noreply, state}
  end

  # handle_cast for :append_state_event
  def handle_cast({:append_state_event, mx_user_id, device, room_id, event}, state) do
    Map.fetch!(state, mx_user_id)
    |> Enum.filter(fn {device_id, _pid} -> device_id != device.device_id end)
    |> Enum.each(fn {_device_id, pid} -> SyncState.append_state(pid, room_id, event) end)

    {:noreply, state}
  end

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

      # drain_state(
      #   sync_state,
      #   Events.latest_timestamp_across_room_ids([room.room_id]) |> Integer.to_string()
      # )
    end)

    {:noreply, state}
  end

  # handle_call for :user_in_room?
  def handle_call({:user_in_room?, mx_user_id, room_id}, _from, state) do
    devices = Map.fetch!(state, mx_user_id)

    first_device_id =
      devices
      |> Map.keys()
      |> List.first()

    reply =
      Map.fetch!(devices, first_device_id)
      |> SyncState.get_joined_room_ids()
      |> Enum.member?(room_id)

    {:reply, reply, state}
  end

  # handle_call for :build_sync
  # TODO - implement filtering
  def handle_call(
        {:build_sync, mx_user_id, device, filter, timeout, params},
        from,
        state
      )
      when is_nil(filter) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    since = Map.get(params, "since", "0")
    full_state = Map.get(params, "full_state", false)

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    cursor = SyncState.get_cursor(sync_state)

    reply =
      if since < cursor do
        SyncState.get_since(sync_state, since, full_state)
      else
        SyncState.get(sync_state, full_state)
      end

    if !full_state and SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout, params}
      )

      {:noreply, state}
    else
      drain_state(sync_state, since)

      {:reply, SyncResponse.drop_empty_fields(reply), state}
    end
  end

  def handle_call({:build_sync, mx_user_id, device, filter, timeout, params}, from, state) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)
    since = Map.get(params, "since", "0")

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    cursor = SyncState.get_cursor(sync_state)

    reply =
      if since < cursor do
        SyncState.get_since(sync_state, since, full_state)
      else
        SyncState.get(sync_state, full_state)
      end

    if !full_state and SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout, params}
      )

      {:noreply, state}
    else
      drain_state(sync_state, since)

      {:reply, SyncResponse.drop_empty_fields(reply), state}
    end
  end

  # TODO - implement filtering
  def handle_info({:check_sync, from, mx_user_id, device, filter, timeout, params}, state) do
    since = Map.get(params, "since", "0")

    sync_state = Map.fetch!(state, mx_user_id) |> Map.fetch!(device.device_id)
    cursor = SyncState.get_cursor(sync_state)

    reply =
      if since < cursor do
        SyncState.get_since(sync_state, since, false)
      else
        SyncState.get(sync_state, false)
      end

    if SyncResponse.is_empty?(reply) and timeout > 0 do
      :timer.send_after(
        1000,
        {:check_sync, from, mx_user_id, device, filter, timeout - 1000, params}
      )

      {:noreply, state}
    else
      GenServer.reply(from, SyncResponse.drop_empty_fields(reply))
      drain_state(sync_state, since)
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
        room_ids = rooms_with_join_type |> Enum.map(fn {room, _join_type} -> room.room_id end)

        SyncState.set_next_batch_to_latest(
          sync_state,
          Events.latest_timestamp_across_room_ids(room_ids) || 0 |> Integer.to_string()
        )

        sync_state

      _ ->
        raise("Failed to start sync state")
    end
  end

  defp drain_state(sync_state, since) do
    SyncState.drain(sync_state, since)
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
    |> Enum.filter(fn room -> Events.membership_in_room?(room.room_id, mx_user_id) end)
    |> Enum.map(fn room -> {room, Events.latest_membership_type(room.room_id, mx_user_id)} end)
  end
end
