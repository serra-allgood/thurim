defmodule Thurim.Sync.SyncResponse do
  def new do
    %{
      "account_data" => %{"events" => []},
      "device_lists" => [],
      "device_one_time_keys_count" => %{},
      "next_batch" => "0",
      "presence" => %{"events" => []},
      "rooms" => %{
        "invite" => %{},
        "join" => %{},
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
            Enum.empty?(timeline["events"]) && Enum.empty?(state["events"])
          end)

        _ ->
          true
      end
    end)
  end

  def drop_empty_fields(response) do
    Map.update!(response, "rooms", fn rooms ->
      Map.reject(rooms, fn {join_type, room_ids} ->
        case join_type do
          "knock" ->
            true

          "leave" ->
            true

          "invite" ->
            Map.reject(room_ids, fn {_room_id, room_events} ->
              Enum.empty?(room_events["events"])
            end)
            |> Enum.empty?()

          "join" ->
            Map.reject(room_ids, fn {_room_id, join_values} ->
              Map.reject(join_values, fn {join_key, join_value} ->
                case join_key do
                  "account_data" ->
                    Enum.empty?(join_value["events"])

                  "ephemeral" ->
                    Enum.empty?(join_value["events"])

                  "state" ->
                    Enum.empty?(join_value["events"])

                  "summary" ->
                    true

                  "timeline" ->
                    Enum.empty?(join_value["events"])

                  "unread_notifications_count" ->
                    Enum.all?(join_value, fn {_notification_key, notification_value} ->
                      notification_value == 0
                    end)
                end
              end)
              |> Enum.empty?()
            end)
            |> Enum.empty?()
        end
      end)
    end)
    |> Map.reject(fn {key, value} ->
      case key do
        "account_data" ->
          Enum.empty?(value["events"])

        "device_lists" ->
          Enum.empty?(value)

        "device_one_time_keys_count" ->
          Enum.empty?(value)

        "next_batch" ->
          false

        "presence" ->
          Enum.empty?(value["events"])

        "rooms" ->
          is_empty?(response)
      end
    end)
  end
end
