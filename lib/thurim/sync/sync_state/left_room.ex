defmodule Thurim.Sync.SyncState.LeftRoom do
  alias Thurim.Events

  def new() do
    %{
      account_data: [],
      state: %{events: []},
      timeline: %{
        events: [],
        limited: false,
        prev_batch: ""
      }
    }
  end

  def new(room_id, _filter, since) do
    timeline = Events.timeline_for_room_id(room_id, since)
    timeline_ids = Enum.map(timeline, & &1.id)

    state =
      Events.state_events_for_room_id(room_id, since)
      |> Enum.filter(&(!Enum.member?(timeline_ids, &1.id)))

    new()
    |> put_in([:state, :events], state |> Enum.map(&Events.map_client_event(&1, true)))
    |> put_in([:timeline, :events], timeline |> Enum.map(&Events.map_client_event(&1, true)))
    |> put_in([:timeline, :prev_batch], since)
    |> put_in([:timeline, :limited], false)
  end

  def empty?({_room_id, response}) do
    Enum.empty?(response.timeline.events) && Enum.empty?(response.state.events)
  end
end
