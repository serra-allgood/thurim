defmodule Thurim.Sync.SyncState do
  use Agent
  alias Thurim.Sync.SyncResponse
  alias Thurim.Sync.SyncResponse.InviteRooms
  alias Thurim.Sync.SyncResponse.JoinRooms

  def start_link(_opts) do
    Agent.start_link(fn ->
      SyncResponse.new()
    end)
  end

  def get(pid, full_state) do
    state = Agent.get(pid, & &1)

    if full_state do
      joined_rooms =
        Map.fetch!(state, :rooms) |> Map.fetch!(:join) |> Enum.map(fn {room_id, _} -> room_id end)
    else
    end
  end

  def add_room_with_type(pid, {room, join_type}) do
    Agent.update(pid, fn state ->
      Map.put(
        state,
        :rooms,
        Map.fetch!(state, :rooms)
        |> Map.update!(join_type, &Map.put(&1, room.room_id, empty_room(join_type)))
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

  defp empty_room("invite") do
    InviteRooms.new()
  end

  defp empty_room("leave") do
    # TODO
    %{}
  end

  defp empty_room("knock") do
    # TODO
    %{}
  end

  defp empty_room("join") do
    JoinRooms.new()
  end

  defp empty_room(_other) do
    %{}
  end
end
