defmodule Thurim.Events.StrippedEventData do
  def new(event) do
    %{
      "content" => event.content,
      "sender" => event.sender,
      "state_key" => event.state_key,
      "type" => event.type
    }
  end

  def stripped_events do
    [
      # "m.room.create",
      # # "m.room.name",
      # "m.room.avatar",
      # # "m.room.topic",
      # "m.room.join_rules",
      # "m.room.canonical_alias",
      "m.room.encryption"
    ]
  end
end
