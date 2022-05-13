defmodule Thurim.Sync.SyncState do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn ->
      %{
        "account_data" => [],
        "device_lists" => [],
        "device_one_time_keys_count" => 0,
        "next_batch" => 0,
        "presence" => [],
        "rooms" => %{
          "invite" => %{},
          "join" => %{},
          "knock" => %{},
          "leave" => %{}
        }
      }
    end)
  end

  def get(pid, _full_state) do
    Agent.get(pid, & &1)
  end

  def add_room_with_type(pid, {room, join_type}) do
    Agent.update(pid, fn state ->
      Map.put(
        state,
        "rooms",
        Map.fetch!(state, "rooms")
        |> Map.update!(join_type, &Map.put(&1, room.room_id, empty_room(join_type)))
      )
    end)
  end

  defp empty_room("invite") do
    %{"events" => []}
  end

  defp empty_room("leave") do
    # TODO
    %{}
  end

  defp empty_room("knock") do
    # TODO
    %{}
  end

  defp empty_room("joined") do
    %{
      "account_data" => [],
      "emphemeral" => [],
      "state" => [],
      "summary" => %{
        "m.heroes" => [],
        "m.invited_member_count" => 0,
        "m.joined_member_count" => 0
      },
      "timeline" => %{"events" => [], "limited" => false, "prev_batch" => 0},
      "unread_notifications_count" => %{"highlight_count" => 0, "notification_count" => 0}
    }
  end

  defp empty_room(_other) do
    %{}
  end
end
