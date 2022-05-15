defmodule Thurim.Events.EventData do
  def new(content, event_id, origin_server_ts, room_id, sender, type, state_key \\ nil) do
    if is_nil(state_key) do
      %{
        "content" => content,
        "event_id" => event_id,
        "origin_server_ts" => origin_server_ts,
        "room_id" => room_id,
        "sender" => sender,
        "type" => type
      }
    else
      %{
        "content" => content,
        "event_id" => event_id,
        "origin_server_ts" => origin_server_ts,
        "room_id" => room_id,
        "sender" => sender,
        "type" => type,
        "state_key" => state_key
      }
    end
  end
end
