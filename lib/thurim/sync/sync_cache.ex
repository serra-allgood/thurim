defmodule Thurim.Sync.SyncCache do
  require WaitForIt

  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local

  alias Thurim.Sync.SyncState
  alias Thurim.Sync.SyncState.{InvitedRoom, JoinedRoom, KnockedRoom, LeftRoom}
  alias Thurim.{Events, Rooms, Rooms.RoomServer}

  def fetch_sync(sender, filter, timeout, params) do
    case Map.fetch(params, "since") do
      {:ok, since} ->
        check_sync(sender, filter, timeout, params, since)

      :error ->
        build_sync(sender, filter, timeout, params, nil)
    end
  end

  def check_sync(sender, filter, timeout, params, since) do
    case get({sender, since}) do
      nil -> build_sync(sender, filter, timeout, params, since)
      cached -> cached
    end
  end

  def build_sync(sender, filter, 0 = _timeout, params, since) do
    {^sender, response} = sync_helper(sender, filter, params, since)
    response
  end

  def build_sync(sender, filter, timeout, params, since) do
    WaitForIt.case_wait sync_helper(sender, filter, params, since, poll: true),
      signal: :sync_update,
      timeout: timeout do
      {^sender, response} -> response
    else
      _ ->
        Rooms.list_rooms()
        |> Enum.map(fn {room, _} -> room end)
        |> silence_updates()

        empty_state(since)
    end
  end

  @doc """
  base_sync_helper
  1. Get rooms for user
  2. Get current sync point, will be the next_batch in response
  3. For each room response type, diff from since and now and aggregate results
  """

  def base_sync_helper(sender, filter, _params, since) do
    current_rooms = Rooms.all_user_rooms(sender)

    Events.max_stream_ordering()
    |> SyncState.new()
    |> Map.from_struct()
    |> update_in([:rooms], fn rooms ->
      # Add invite rooms
      rooms
      |> Map.from_struct()
      |> update_in([:invite], fn invite ->
        current_rooms
        |> filter_rooms("invite")
        |> Enum.reduce(invite, fn {room, _membership_events}, invite ->
          invite_state_events = Events.invite_state_events(room.room_id, sender, since)
          put_in(invite, [room.room_id], InvitedRoom.new(invite_state_events))
        end)
        |> Map.reject(&InvitedRoom.empty?/1)
      end)
      # Add join rooms
      |> update_in([:join], fn join ->
        current_rooms
        |> filter_rooms("join")
        |> Enum.reduce(join, fn {room, _membership_events}, join ->
          put_in(join, [room.room_id], JoinedRoom.new(room.room_id, sender, filter, since))
        end)
        |> Map.reject(&JoinedRoom.empty?/1)
      end)
    end)
  end

  def sync_helper(sender, filter, params, since, opts \\ []) do
    poll = Keyword.get(opts, :poll, false)
    response = base_sync_helper(sender, filter, params, since)

    cond do
      !SyncState.empty?(response) ->
        put({sender, nil}, response)
        WaitForIt.signal(:sync_update)
        {sender, response}

      poll ->
        current_rooms = Rooms.all_user_rooms(sender) |> Enum.map(fn {room, _} -> room end)
        listen_for_updates(current_rooms)

        receive do
          {:room_update, room_id} ->
            if current_rooms |> Enum.map(& &1.room_id) |> Enum.member?(room_id) do
              silence_updates(current_rooms)
              sync_helper(sender, filter, params, since)
            end
        end

      true ->
        {sender, response}
    end
  end

  defp empty_state(prev_batch) do
    SyncState.new(prev_batch)
  end

  defp filter_rooms(rooms, membership_type) do
    Enum.filter(rooms, fn {_room, membership_events} ->
      List.last(membership_events) == membership_type
    end)
  end

  defp listen_for_updates(rooms) do
    Enum.each(rooms, &RoomServer.register_listener(&1.room_id, self()))
  end

  defp silence_updates(rooms) do
    Enum.each(rooms, &RoomServer.unregister_listener(&1.room_id, self()))
  end
end
