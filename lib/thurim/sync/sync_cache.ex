defmodule Thurim.Sync.SyncCache do
  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local

  alias Thurim.Sync.SyncState
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
    rooms = Rooms.base_user_rooms(sender)
    current_count = Events.get_current_count()
  end

  defp empty_state(prev_batch) do
    SyncState.new(prev_batch)
  end
end
