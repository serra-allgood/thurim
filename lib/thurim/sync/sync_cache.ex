defmodule Thurim.Sync.SyncCache do
  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local

  def fetch_sync(sender, device, filter, timeout, params) do
    case Map.fetch(params, "since") do
      {:ok, since} ->
        case get({sender, device, since}) do
          nil -> build_sync(sender, device, filter, timeout, params, since)
          cached -> cached
        end

      :error ->
        build_sync(sender, device, filter, timeout, params)
    end
  end

  def check_sync(sender, device, filter, timeout, params, since) do
    cached = get({sender, device.device_id, since})

    if !cached do
      build_sync(sender, device, filter, timeout, params)
    else
      cached
    end
  end

  def build_sync(sender, device, filter, timeout, params, since \\ nil)

  def build_sync(sender, device, filter, 0, params, since) when is_nil(since) do
    Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
      sync_helper(sender, device, filter, params)
    end)
    |> Task.await()
  end

  def build_sync(sender, device, filter, timeout, params, since) when is_nil(since) do
    try do
      Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
        sync_helper(sender, device, filter, params, poll: true)
      end)
      |> Task.await(timeout)
    catch
      :exit, {:timeout, _} -> empty_sync_state()
    end
  end

  def build_sync(sender, device, filter, timeout, params, since) do
    try do
      Task.Supervisor.async(Thurim.SyncTaskSupervisor, fn ->
        sync_helper(sender, device, filter, params, poll: true, since: since)
      end)
    catch
      :exit, {:timeout, _} -> empty_sync_state()
    end
  end

  def sync_helper(sender, device, filter, params, opts \\ [poll: false]) do
  end

  def empty_sync_state() do
  end
end
