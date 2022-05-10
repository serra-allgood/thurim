defmodule Thurim.Sync.SyncServer do
  use GenServer
  alias Thurim.Presence
  alias Thurim.Sync.Cursor
  alias Thurim.User
  alias Thurim.Rooms

  # Sync state looks like the following:
  # %{
  #   [localpart] => %{
  #     [device_id] => {cursor, %{[room_id] => %{"state" => [], "ephemereal" => []}}}
  #   }
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

  def build_sync(account, device, filter, params) do
    GenServer.call(__MODULE__, {:build_sync, account, device, filter, params})
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
           {cursor, Map.put(rooms, room.room_id, %{"state" => [], "ephemereal" => []})}}
        end)
        |> Enum.into(%{})
      end)

    {:noreply, new_state}
  end

  # handle_call for :build_sync
  def handle_call(
        {:build_sync, account, device, filter, params = %{"since" => since}},
        _from,
        state
      )
      when is_nil(filter) do
    Map.get(params, "set_presence", false) |> handle_presence(account)

    {:reply}
  end

  def handle_call({:build_sync, account, device, filter, params}, _from, state)
      when is_nil(filter) do
    Map.get(params, "set_presence", false) |> handle_presence(account)

    {cursor, rooms} = Map.get(state, account.localpart, %{}) |> Map.get(device.device_id, {})

    {new_cursor, reply} = build_response(cursor, rooms)

    {:reply, reply, drain_state(state, account, device, new_cursor, rooms)}
  end

  defp handle_presence(set_presence, account) do
    if set_presence do
      Presence.set_user_presence(Thurim.User.mx_user_id(account.localpart), set_presence)
    end
  end

  defp build_response(cursor, rooms) do
    {cursor, rooms}
  end

  defp drain_state(state, account, device, new_cursor, rooms) do
    Map.update!(state, account.localpart, fn devices ->
      Map.put(
        devices,
        device.device_id,
        {new_cursor,
         rooms
         |> Enum.map(fn {room_id, _events} -> {room_id, %{"state" => [], "ephemereal" => []}} end)
         |> Enum.into(%{})}
      )
    end)
  end

  defp build_state_from_db() do
    User.list_accounts_with_devices()
    |> Enum.map(fn account ->
      {account.localpart,
       account.devices
       |> map_devices_to_rooms(account)}
    end)
    |> Enum.into(%{})
  end

  defp map_devices_to_rooms(devices, account) do
    devices
    |> Enum.map(fn device ->
      {device.device_id, {Cursor.new(), default_room_event_state(account)}}
    end)
    |> Enum.into(%{})
  end

  defp default_room_event_state(account) do
    rooms_with_localparts()
    |> Enum.filter(fn {_room, localparts} ->
      Enum.member?(localparts, account.localpart)
    end)
    |> Enum.map(fn {room, _localparts} ->
      {room.room_id, %{"state" => [], "ephemereal" => []}}
    end)
    |> Enum.into(%{})
  end

  defp rooms_with_localparts do
    Rooms.list_rooms()
    |> Enum.map(fn room ->
      {room,
       User.users_in_room(room)
       |> Enum.map(&User.extract_localpart/1)}
    end)
  end
end
