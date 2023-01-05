defmodule Thurim.Sync.SyncCache do
  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local

  alias Thurim.Sync.SyncState
  alias Thurim.Sync.SyncState.{InvitedRoom, JoinedRoom, KnockedRoom, LeftRoom}
  alias Thurim.{Events, Rooms}

  def fetch_sync(sender, device_id, filter, timeout, params) do
    case Map.fetch(params, "since") do
      {:ok, since} ->
        check_sync(sender, device_id, filter, timeout, params, since)

      :error ->
        build_sync(sender, device_id, filter, timeout, params)
    end
  end

  def check_sync(sender, device_id, filter, timeout, params, since) do
    case get({sender, device_id, since}) do
      nil -> build_sync(sender, device_id, filter, timeout, params, since)
      cached -> cached
    end
  end

  def build_sync(sender, device_id, filter, timeout, params, since \\ nil)

  def build_sync(sender, device_id, filter, 0, params, since) when is_nil(since) do
    Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
      sync_helper(sender, device_id, filter, params)
    end)
    |> Task.await()
  end

  def build_sync(sender, device_id, filter, timeout, params, since) when is_nil(since) do
    try do
      Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
        sync_helper(sender, device_id, filter, params, %{poll: true})
      end)
      |> Task.await(timeout)
    catch
      :exit, {:timeout, _} -> empty_state(since)
    end
  end

  def build_sync(sender, device_id, filter, timeout, params, since) do
    try do
      Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
        sync_helper(sender, device_id, filter, params, %{poll: true, since: since})
      end)
      |> Task.await(timeout)
    catch
      :exit, {:timeout, _} -> empty_state(since)
    end
  end

  @doc """
  sync_helper
  1. Get rooms for user
  2. Get current sync point, will be the next_batch in response
  3. For each room response type, diff from since and now and aggregate results
  """
  def sync_helper(sender, device_id, filter, params, opts \\ %{poll: false, since: nil})

  def sync_helper(sender, device_id, filter, params, %{poll: false, since: nil}) do
    current_rooms = Rooms.base_user_rooms(sender)

    response =
      Events.get_current_count()
      |> SyncState.new()
      |> update_in(:rooms, fn rooms ->
        # Add invite rooms
        update_in(rooms.invite, fn invite ->
          current_rooms
          |> filter_rooms("invite")
          |> Enum.reduce(invite, fn {room, _membership_events} ->
            invite_state_events = Events.invite_state_events(room.room_id, sender)
            put_in(invite, room.room_id, InvitedRoom.new(invite_state_events))
          end)
        end)
        # Add join rooms
        |> update_in(rooms.join, fn join ->
          current_rooms
          |> filter_rooms("join")
          |> Enum.reduce(join, fn {room, _membership_events} ->
            put_in(join, room.room_id, JoinedRoom.new(room.room_id, sender))
          end)
        end)
      end)
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
