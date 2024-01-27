defmodule Thurim.Sync.SyncState.JoinedRoom do
  alias Thurim.Events
  alias Thurim.Rooms.RoomServer

  def new() do
    %{
      account_data: %{events: []},
      ephemeral: %{events: []},
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
    %{latest_update: latest_typing_update, typings: typing_users} = RoomServer.get_typing(room_id)

    # TODO: Does state for `limited: false` need to be altered by `since`?
    state =
      Events.state_events_for_room_id(room_id, nil)
      |> Enum.filter(&(!Enum.member?(timeline_ids, &1.id)))

    joined_room =
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

    if latest_typing_update > String.to_integer(since) do
      typing_event = %{content: %{user_ids: typing_users}, type: "m.typing"}

      joined_room
      |> put_in([:ephemeral, :events], [typing_event])
    else
      joined_room
    end
  end

  def empty?({_room_id, response}) do
    Enum.empty?(response.timeline.events) && Enum.empty?(response.ephemeral.events)
  end
end
