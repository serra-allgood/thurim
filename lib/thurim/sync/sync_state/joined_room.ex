defmodule Thurim.Sync.SyncState.JoinedRoom do
  alias Thurim.Events

  @derive Jason.Encoder
  defstruct [
    :account_data,
    :ephemereal,
    :state,
    :summary,
    :timeline,
    :unread_notifications,
    :unread_thread_notifications
  ]

  def new() do
    %{
      account_data: %{events: []},
      ephemereal: %{events: []},
      state: %{events: []},
      # summary includes the keys m.heroes, m.invited_member_count, and m.joined_member_count,
      # but may omit any of them if they have not changed since the last sync
      summary: %{},
      timeline: %{
        events: [],
        limited: false,
        prev_batch: ''
      },
      unread_notifications: %{
        highlight_count: 0,
        notification_count: 0
      },
      unread_thread_notifications: %{
        highlight_count: 0,
        notification_count: 0
      }
    }
  end

  def new(room_id, mx_user_id, _filter, since) do
    timeline = Events.timeline_for_room_id(room_id, since)
    timeline_ids = Enum.map(timeline, & &1.id)

    state =
      Events.state_events_for_room_id(room_id, since)
      |> Enum.filter(&(!Enum.member?(timeline_ids, &1.id)))

    new()
    |> update_in([:summary], fn summary ->
      heroes = Events.heroes_for_room_id(room_id, mx_user_id)
      invited_member_count = Events.invited_member_count(room_id)
      joined_member_count = Events.joined_member_count(room_id)

      put_in(summary, ["m.heroes"], heroes)
      |> put_in(["m.invited_member_count"], invited_member_count)
      |> put_in(["m.joined_member_count"], joined_member_count)
    end)
    |> put_in([:state, :events], state |> Enum.map(&Events.map_client_event(&1, true)))
    |> put_in([:timeline, :events], timeline |> Enum.map(&Events.map_client_event(&1, true)))
    |> put_in([:timeline, :prev_batch], since)
    |> put_in([:timeline, :limited], false)
  end

  def empty?({_room_id, response}) do
    Enum.empty?(response.timeline.events) && Enum.empty?(response.state.events)
  end
end
