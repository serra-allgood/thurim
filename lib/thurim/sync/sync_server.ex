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

  def add_device(mx_user_id, device_id) do
    GenServer.cast(__MODULE__, {:add_device, mx_user_id, device_id})
  end

  def add_user(mx_user_id, device) do
    GenServer.cast(__MODULE__, {:add_user, mx_user_id, device})
  end

  def add_room(room, mx_user_id) do
    GenServer.cast(__MODULE__, {:add_room, room, mx_user_id})
  end

  def build_sync(mx_user_id, device, filter, params) do
    GenServer.call(__MODULE__, {:build_sync, mx_user_id, device, filter, params})
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
        |> Map.put(device_id, new_sync_state(rooms_with_mx_user_id(mx_user_id)))
      )

    {:noreply, new_state}
  end

  # handle_cast for :add_user
  def handle_cast({:add_user, mx_user_id, device}, state) do
    new_state =
      Map.put(state, mx_user_id, %{
        device.device_id => new_sync_state(rooms_with_mx_user_id(mx_user_id))
      })

    {:noreplay, new_state}
  end

  # handle_cast for :add_room
  def handle_cast({:add_room, room, mx_user_id}, state) do
    new_state =
      Map.put(
        state,
        mx_user_id,
        Map.fetch!(state, mx_user_id)
        |> Enum.map(fn {device_id, pid} ->
          SyncState.add_room_with_type(pid, {room, "join"})
          {device_id, pid}
        end)
        |> Enum.into(%{})
      )

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

    reply = %{}

    {:reply, reply, drain_state(state, mx_user_id, device, reply)}
  end

  def handle_call({:build_sync, mx_user_id, device, filter, params}, _from, state)
      when is_nil(filter) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)
    full_state = Map.get(params, "full_state", false)

    reply = build_response(state, mx_user_id, device, full_state)

    {:reply, reply, drain_state(state, mx_user_id, device, reply)}
  end

  def handle_call({:build_sync, mx_user_id, device, filter, params}, _from, state) do
    Map.get(params, "set_presence", false) |> handle_presence(mx_user_id)

    reply = %{}

    {:reply, reply, drain_state(state, mx_user_id, device, reply)}
  end

  defp handle_presence(set_presence, mx_user_id) do
    if set_presence do
      Presence.set_user_presence(mx_user_id, set_presence)
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

  defp build_response(state, account, device, full_state) do
    Map.get(state, account.localpart, %{})
    |> Map.fetch!(device.device_id)
    |> SyncState.get(full_state)
  end

  defp drain_state(state, mx_user_id, device, reply) do
    Map.fetch!(state, mx_user_id)
    |> Map.fetch!(device.device_id)
    |> SyncState.drain(reply["cursor"])

    state
  end

  defp build_state_from_db() do
    User.list_accounts_with_devices()
    |> Enum.map(fn account ->
      mx_user_id = User.mx_user_id(account.localpart)

      {mx_user_id,
       account.devices
       |> map_devices_to_sync_state(mx_user_id)}
      |> Enum.into(%{})
    end)
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
