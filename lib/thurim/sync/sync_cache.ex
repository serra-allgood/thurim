defmodule Thurim.Sync.SyncCache do
  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local

  alias Thurim.Sync.SyncState
  alias Thurim.Sync.SyncState.{InvitedRoom, JoinedRoom, KnockedRoom, LeftRoom}
  alias Thurim.{Events, Rooms}

  def fetch_sync(sender, filter, timeout, params) do
    case Map.fetch(params, "since") do
      {:ok, since} ->
        check_sync(sender, filter, timeout, params, since)

      :error ->
        build_sync(sender, filter, timeout, params)
    end
  end

  def check_sync(sender, filter, timeout, params, since) do
    case get({sender, since}) do
      nil -> build_sync(sender, filter, timeout, params, since)
      cached -> cached
    end
  end

  def build_sync(sender, filter, timeout, params, since \\ nil)

  def build_sync(sender, filter, 0, params, since) when is_nil(since) do
    Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
      sync_helper(sender, filter, params)
    end)
    |> Task.await()
  end

  def build_sync(sender, filter, timeout, params, since) when is_nil(since) do
    try do
      Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
        sync_helper(sender, filter, params, %{poll: true})
      end)
      |> Task.await(timeout)
    catch
      :exit, {:timeout, _} -> empty_state(since)
    end
  end

  def build_sync(sender, filter, timeout, params, since) do
    try do
      Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
        sync_helper(sender, filter, params, %{poll: true, since: since})
      end)
      |> Task.await(timeout)
    catch
      :exit, {:timeout, _} -> empty_state(since)
    end
  end

  @doc """
  base_sync_helper
  1. Get rooms for user
  2. Get current sync point, will be the next_batch in response
  3. For each room response type, diff from since and now and aggregate results
  """
  def base_sync_helper(sender, filter, _params) do
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
          invite_state_events = Events.invite_state_events(room.room_id, sender)
          put_in(invite, room.room_id, InvitedRoom.new(invite_state_events))
        end)
        |> Map.reject(&InvitedRoom.empty?/1)
      end)
      # Add join rooms
      |> update_in([:join], fn join ->
        current_rooms
        |> filter_rooms("join")
        |> Enum.reduce(join, fn {room, _membership_events}, join ->
          put_in(join, room.room_id, JoinedRoom.new(room.room_id, sender, filter))
        end)
        |> Map.reject(&JoinedRoom.empty?/1)
      end)
    end)
  end

  def sync_helper(sender, filter, params, opts \\ %{poll: false, since: nil})

  def sync_helper(sender, filter, params, %{poll: false, since: nil}) do
    response = base_sync_helper(sender, filter, params)

    if !SyncState.empty?(response) do
      put({sender, nil}, response)
    end

    response
  end

  def sync_helper(sender, filter, params, %{poll: true, since: nil}) do
    response = base_sync_helper(sender, filter, params)

    if !SyncState.empty?(response) do
      put({sender, nil}, response)
    else
      sync_helper(sender, filter, params, %{poll: true, since: nil})
    end

    response
  end

  def sync_helper(sender, filter, params, %{poll: false, since: since}) do
    response
  end

  defp empty_state(prev_batch) do
    SyncState.new(prev_batch)
  end

  defp filter_rooms(rooms, membership_type) do
    Enum.filter(rooms, fn {_room, membership_events} ->
      List.last(membership_events) == membership_type
    end)
  end
end
