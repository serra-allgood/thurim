defmodule Thurim.Sync.SyncResponse do
  alias Thurim.Sync.SyncResponse.InviteRooms
  alias Thurim.Sync.SyncResponse.JoinRooms

  def new do
    %{
      "account_data" => [],
      "device_lists" => [],
      "device_one_time_keys_count" => 0,
      "next_batch" => "0",
      "presence" => [],
      "rooms" => %{
        "invite" => InviteRooms.new(),
        "join" => JoinRooms.new(),
        "knock" => %{},
        "leave" => %{}
      }
    }
  end

  def new(partial_response) do
    Map.merge(new(), partial_response)
  end

  def is_empty?(response) do
    Map.get(response, "rooms")
    |> Enum.all?(fn {join_type, value} ->
      case join_type do
        "knock" ->
          true

        "leave" ->
          true

        "invite" ->
          Enum.all?(value, fn {_room_id, events} -> Enum.empty?(events) end)

        "join" ->
          Enum.all?(value, fn {_room_id,
                               %{"timeline" => timeline, "state" => state} = _join_values} ->
            Enum.empty?(timeline["events"]) && Enum.empty?(state)
          end)

        _ ->
          true
      end
    end)
  end
end
