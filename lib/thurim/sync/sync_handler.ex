defmodule Thurim.Sync.SyncHandler do
  alias Thurim.Sync.CursorAgent
  alias Thurim.Filters
  alias Thurim.Sync.StreamingToken
  alias Thurim.Sync.CursorWorker

  @type sync_req :: %{
          timeout: integer,
          filter: map,
          since: StreamingToken.t(),
          want_full_state: boolean
        }

  def get_updates(account, device, params) do
    sync_req = new_sync_req(account.localpart, params)
    {:ok, agent} = CursorAgent.get_agent(account.localpart, device.id)
    current_position = CursorAgent.get_current_position(agent)

    if !return_immediately(sync_req, current_position) do
      task =
        Task.Supervisor.async_nolink(Thurim.SyncSupervisor, CursorWorker, :get_updates, [
          current_position,
          sync_req
        ])

      case Task.yield(task, sync_req.timeout) || Task.shutdown(task) do
        {:ok, new_position} ->
          CursorAgent.update(agent, new_position)
          {:ok, build_response(new_position)}

        {:exit, _} ->
          {:ok, %{next_batch: StreamingToken.to_string(sync_req.since)}}
      end
    end
  end

  @spec return_immediately(sync_req(), StreamingToken.t()) :: boolean
  def return_immediately(sync_req, current_position) do
    sync_req.timeout == 0 || sync_req.want_full_state ||
      StreamingToken.is_after?(sync_req.since, current_position)
  end

  @spec new_sync_req(String.t(), map) :: sync_req()
  def new_sync_req(localpart, params) do
    timeout = Map.get(params, "timeout", 0)
    filter = Map.get(params, "filter", "")

    filter =
      if !String.starts_with?(filter, "{") do
        Filters.get_by!(localpart: localpart, id: filter).filter
      else
        Jason.decode(filter)
      end

    since = Map.get(params, "since") |> StreamingToken.new()
    want_full_state = Map.get(params, "full_state", false)

    %{timeout: timeout, filter: filter, since: since, want_full_state: want_full_state}
  end

  @spec build_response(StreamingToken.t()) :: map
  def build_response(position) do
  end
end
