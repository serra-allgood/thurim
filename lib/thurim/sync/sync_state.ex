defmodule Thurim.Sync.SyncState do
  use Agent
  alias Thurim.Sync.SyncResponse
  alias Thurim.Sync.SyncResponse.InviteRooms
  alias Thurim.Sync.SyncResponse.JoinRooms
  alias Thurim.Events
  alias Thurim.User
  require Logger

  def start_link(_opts) do
    Agent.start_link(fn ->
      {"0", SyncResponse.new()}
    end)
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  def get_cursor(pid) do
    Agent.get(pid, fn {cursor, _response} -> cursor end)
  end

  def get(pid, full_state) do
    {_cursor, response} = Agent.get(pid, & &1)

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
               |> Enum.map(&Events.map_client_event(&1, true))
           }}
        end)
        |> Enum.into(%{})

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
      )
    else
      response
    end
  end

  def get_since(pid, _since, full_state) do
    # TODO
    Logger.debug("get_since called")
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
         Events.latest_timestamp_across_room_ids([room.room_id]) |> Integer.to_string()
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
               state: state |> Enum.map(fn event -> Events.map_client_event(event, true) end),
               timeline:
                 timeline |> Enum.map(fn event -> Events.map_client_event(event, true) end)
             )
           )
         )
       )}
    end)
  end

  def append_state(pid, room_id, event) do
    Agent.update(pid, fn {cursor, response} ->
      {cursor,
       Map.put(response, "next_batch", event.origin_server_ts |> Integer.to_string())
       |> Map.put(
         "rooms",
         Map.fetch!(response, "rooms")
         |> Map.update!("join", fn joined_rooms ->
           if Enum.member?(Map.keys(joined_rooms), room_id) do
             Map.put(
               joined_rooms,
               room_id,
               Map.fetch!(joined_rooms, room_id)
               |> Map.update!("state", fn state ->
                 Map.put(
                   state,
                   "events",
                   state["events"] ++ [Events.map_client_event(event, true)]
                 )
               end)
             )
           else
             joined_rooms
           end
         end)
       )}
    end)
  end

  def append_timeline(pid, room_id, event) do
    Agent.update(pid, fn {cursor, response} ->
      {cursor,
       Map.put(response, "next_batch", event.origin_server_ts |> Integer.to_string())
       |> Map.put(
         "rooms",
         Map.fetch!(response, "rooms")
         |> Map.update!("join", fn joined_rooms ->
           if Enum.member?(Map.keys(joined_rooms), room_id) do
             Map.put(
               joined_rooms,
               room_id,
               Map.fetch!(joined_rooms, room_id)
               |> Map.update!("timeline", fn timeline ->
                 Map.put(
                   timeline,
                   "events",
                   timeline["events"] ++ [Events.map_client_event(event, true)]
                 )
               end)
             )
           else
             joined_rooms
           end
         end)
       )}
    end)
  end

  def set_next_batch_to_latest(pid, next_batch) do
    Agent.update(pid, fn {cursor, response} ->
      {cursor, Map.put(response, "next_batch", next_batch)}
    end)
  end

  def drain(pid, since) do
    origin_server_ts = String.to_integer(since)

    # TODO - device_lists, device_one_time_keys_count, presence
    Agent.update(pid, fn {cursor, response} ->
      {response["next_batch"],
       Map.put(
         response,
         "account_data",
         Map.put(
           response["account_data"],
           "events",
           response["account_data"]["events"]
           |> Enum.filter(&(&1["origin_server_ts"] > origin_server_ts))
         )
       )
       #  |> Map.put("next_batch", Events.latest_timestamp() || 0 |> Integer.to_string())
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
                          Map.put(
                            join_value,
                            "events",
                            join_value["events"]
                            |> Enum.filter(
                              &(!is_nil(&1["origin_server_ts"]) and
                                  &1["origin_server_ts"] > origin_server_ts)
                            )
                          )}

                       "ephemeral" ->
                         {join_key,
                          Map.put(
                            join_value,
                            "events",
                            join_value["events"]
                            |> Enum.filter(
                              &(!is_nil(&1["origin_server_ts"]) and
                                  &1["origin_server_ts"] > origin_server_ts)
                            )
                          )}

                       "state" ->
                         {join_key,
                          Map.put(
                            join_value,
                            "events",
                            join_value["events"]
                            |> Enum.filter(
                              &(!is_nil(&1["origin_server_ts"]) and
                                  &1["origin_server_ts"] > origin_server_ts)
                            )
                          )}

                       "summary" ->
                         {join_key,
                          %{
                            "m.heroes" => join_value["m.heroes"],
                            "m.invited_member_count" => 0,
                            "m.joined_member_count" =>
                              User.joined_user_ids_in_room(room_id) |> Enum.count()
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
                            "prev_batch" => cursor
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
    JoinRooms.new(attrs)
  end

  defp empty_room(_join_type, _attrs) do
    %{}
  end

  # defp new_cursor(events) do
  #   Enum.map(events, & &1.origin_server_ts)
  #   |> Enum.filter(fn ts -> ts end)
  #   |> Enum.max(&>=/2, fn -> 0 end)
  #   |> Integer.to_string()
  # end
end
