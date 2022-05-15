defmodule Thurim.Sync.SyncState do
  use Agent
  alias Thurim.Sync.SyncResponse
  alias Thurim.Sync.SyncResponse.InviteRooms
  alias Thurim.Sync.SyncResponse.JoinRooms
  alias Thurim.Events
  alias Thurim.Events.EventData
  alias Thurim.Events.StrippedEventData

  def start_link(_opts) do
    Agent.start_link(fn ->
      SyncResponse.new()
    end)
  end

  def get(pid, full_state) do
    state = Agent.get(pid, & &1)

    if full_state do
      room_ids_with_full_state =
        Map.fetch!(state, :rooms)
        |> Map.fetch!(:join)
        |> Map.keys()
        |> Enum.map(&{&1, Events.state_events_for_room_id(&1)})
        |> Enum.map(fn {room_id, events} ->
          {room_id,
           %{
             state:
               events
               |> Enum.map(fn event ->
                 cond do
                   Enum.member?(StrippedEventData.stripped_events(), event.type) ->
                     StrippedEventData.new(
                       event.content,
                       event.sender,
                       event.state_key,
                       event.type
                     )

                   true ->
                     EventData.new(
                       event.content,
                       event.event_id,
                       event.origin_server_ts,
                       event.room_id,
                       event.sender,
                       event.type,
                       event.state_key
                     )
                 end
               end)
           }}
        end)

      Map.put(
        state,
        :rooms,
        Map.update!(state, :rooms, fn rooms ->
          Map.put(rooms, :join, Map.fetch!(rooms, :join) |> Map.merge(room_ids_with_full_state))
        end)
      )
    else
      state
    end
  end

  def add_room_with_type(pid, sender, {room, join_type}) do
    Agent.update(pid, fn state ->
      Map.put(
        state,
        :rooms,
        Map.fetch!(state, :rooms)
        |> Map.update!(
          join_type,
          &Map.put(&1, room.room_id, empty_room(join_type, sender, room.room_id))
        )
      )
    end)
  end

  def drain(pid, cursor) do
    origin_server_ts = String.to_integer(cursor)

    Agent.update(pid, fn state ->
      # TODO - device_lists, device_one_time_keys_count, presence
      Map.put(
        state,
        "account_data",
        Map.fetch!(state, "account_data")
        |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts))
      )
      |> Map.put("next_batch", Integer.to_string(origin_server_ts))
      |> Map.put(
        "rooms",
        Map.fetch!(state, "rooms")
        |> Enum.map(fn {join_type, rooms} ->
          {join_type,
           rooms
           |> Enum.map(fn {key, value} ->
             case join_type do
               "invite" ->
                 {key, value |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts))}

               "knock" ->
                 {key, value}

               "leave" ->
                 {key, value}

               "join" ->
                 case key do
                   "account_data" ->
                     {key, value |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts))}

                   "ephemereal" ->
                     {key, value |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts))}

                   "state" ->
                     {key, value |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts))}

                   "summary" ->
                     {key,
                      %{
                        "m.heroes" => [],
                        "m.invited_member_count" => 0,
                        "m.joined_member_count" => 0
                      }}

                   "timeline" ->
                     {key,
                      %{
                        "events" =>
                          value |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts)),
                        "limited" => false,
                        "prev_batch" => state["next_batch"]
                      }}

                   "unread_notifications_count" ->
                     {key, %{"highlight_count" => 0, "notification_count" => 0}}
                 end
             end
           end)}
        end)
      )
    end)
  end

  defp empty_room("invite", _sender, _room_id) do
    InviteRooms.new()
  end

  defp empty_room("leave", _sender, _room_id) do
    # TODO
    %{}
  end

  defp empty_room("knock", _sender, _room_id) do
    # TODO
    %{}
  end

  defp empty_room("join", sender, room_id) do
    heroes = Events.heroes_for_room_id(room_id, sender)
    state = Events.state_events_for_room_id(room_id)
    JoinRooms.new(heroes, state)
  end

  defp empty_room(_other, _room_id) do
    %{}
  end
end
