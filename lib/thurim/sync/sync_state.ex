defmodule Thurim.Sync.SyncState do
  use Agent
  alias Thurim.Sync.SyncResponse
  alias Thurim.Sync.SyncResponse.InviteRooms
  alias Thurim.Sync.SyncResponse.JoinRooms
  alias Thurim.Events

  def start_link(_opts) do
    Agent.start_link(fn ->
      {"0", SyncResponse.new()}
    end)
  end

  def get_cursor(pid) do
    Agent.get(pid, fn {cursor, _response} -> cursor end)
  end

  def get(pid, full_state) do
    {cursor, response} = Agent.get(pid, & &1)

    if full_state do
      room_ids_with_full_state =
        Map.fetch!(response, "rooms")
        |> Map.fetch!("join")
        |> Map.keys()
        |> Enum.map(&{&1, Events.state_events_for_room_id(&1)})
        |> Enum.map(fn {room_id, events} ->
          {room_id,
           %{
             "state" =>
               events
               |> Enum.map(&Events.map_events/1)
           }}
        end)
        |> Enum.into(%{})

      {cursor,
       Map.put(
         response,
         "rooms",
         Map.update!(response, "rooms", fn rooms ->
           Map.put(
             rooms,
             "join",
             Map.fetch!(rooms, "join")
             |> Enum.map(fn {room_id, room_map} ->
               {room_id, Map.merge(room_map, room_ids_with_full_state[room_id])}
             end)
             |> Enum.into(%{})
           )
         end)
       )}
    else
      {cursor, response}
    end
  end

  def get_since(pid, _since, full_state) do
    # TODO
    get(pid, full_state)
  end

  def get_joined_room_ids(pid) do
    Agent.get(pid, fn {_cursor, response} ->
      Map.fetch!(response, "rooms")
      |> Map.fetch!("join")
      |> Map.keys()
    end)
  end

  def add_room_with_type(pid, sender, {room, join_type}) do
    heroes = Events.heroes_for_room_id(room.room_id, sender)
    timeline = Events.timeline_for_room_id(room.room_id)
    timeline_ids = timeline |> Enum.map(& &1.id)

    state =
      Events.state_events_for_room_id(room.room_id)
      |> Enum.filter(&(!Enum.member?(timeline_ids, &1.id)))

    Agent.update(pid, fn {cursor, response} ->
      {cursor,
       Map.put(
         response,
         "next_batch",
         new_cursor(timeline)
       )
       |> Map.put(
         "rooms",
         Map.fetch!(response, "rooms")
         |> Map.update!(
           join_type,
           &Map.put(
             &1,
             room.room_id,
             empty_room(join_type,
               heroes: heroes,
               state: state |> Enum.map(fn event -> Events.map_events(event) end),
               timeline: timeline |> Enum.map(fn event -> Events.map_events(event) end)
             )
           )
         )
       )}
    end)
  end

  def drain(pid, cursor) do
    origin_server_ts = String.to_integer(cursor)

    # TODO - device_lists, device_one_time_keys_count, presence
    Agent.update(pid, fn {_cursor, response} ->
      {response["next_batch"],
       Map.put(
         response,
         "account_data",
         Map.fetch!(response, "account_data")
         |> Enum.filter(&(&1[:origin_server_ts] > origin_server_ts))
       )
       |> Map.put("next_batch", cursor)
       |> Map.put(
         "rooms",
         Map.fetch!(response, "rooms")
         |> Enum.map(fn {join_type, rooms} ->
           {join_type,
            rooms
            |> Enum.map(fn {room_id, room_values} ->
              case join_type do
                "invite" ->
                  {room_id,
                   room_values
                   |> Enum.filter(
                     &(!is_nil(&1["origin_server_ts"]) and
                         &1["origin_server_ts"] > origin_server_ts)
                   )}

                "knock" ->
                  {room_id, room_values}

                "leave" ->
                  {room_id, room_values}

                "join" ->
                  {room_id,
                   Enum.map(room_values, fn {join_key, join_value} ->
                     case join_key do
                       "account_data" ->
                         {join_key,
                          join_value
                          |> Enum.filter(
                            &(!is_nil(&1["origin_server_ts"]) and
                                &1["origin_server_ts"] > origin_server_ts)
                          )}

                       "ephemeral" ->
                         {join_key,
                          join_value
                          |> Enum.filter(
                            &(!is_nil(&1["origin_server_ts"]) and
                                &1["origin_server_ts"] > origin_server_ts)
                          )}

                       "state" ->
                         {join_key,
                          join_value
                          |> Enum.filter(
                            &(!is_nil(&1["origin_server_ts"]) and
                                &1["origin_server_ts"] > origin_server_ts)
                          )}

                       "summary" ->
                         {join_key,
                          %{
                            "m.heroes" => join_value["m.heroes"],
                            "m.invited_member_count" => 0,
                            "m.joined_member_count" => 0
                          }}

                       "timeline" ->
                         {join_key,
                          %{
                            "events" =>
                              join_value["events"]
                              |> Enum.filter(
                                &(!is_nil(&1["origin_server_ts"]) and
                                    &1["origin_server_ts"] > origin_server_ts)
                              ),
                            "limited" => false,
                            "prev_batch" => response["next_batch"]
                          }}

                       "unread_notifications_count" ->
                         {join_key, %{"highlight_count" => 0, "notification_count" => 0}}
                     end
                   end)
                   |> Enum.into(%{})}
              end
            end)
            |> Enum.into(%{})}
         end)
         |> Enum.into(%{})
       )}
    end)
  end

  defp empty_room("invite", _attrs) do
    InviteRooms.new()
  end

  defp empty_room("leave", _attrs) do
    # TODO
    %{}
  end

  defp empty_room("knock", _attrs) do
    # TODO
    %{}
  end

  defp empty_room("join", attrs) do
    JoinRooms.new(attrs[:heroes], attrs[:state], attrs[:timeline])
  end

  defp empty_room(_join_type, _attrs) do
    %{}
  end

  defp new_cursor(events) do
    Enum.map(events, & &1.origin_server_ts)
    |> Enum.filter(fn ts -> ts end)
    |> Enum.max(&>=/2, fn -> 0 end)
    |> Integer.to_string()
  end
end
