defmodule Thurim.Events.StrippedEventData do
  def new(content, sender, state_key, type) do
    %{"content" => content, "sender" => sender, "state_key" => state_key, "type" => type}
  end

  def stripped_events do
    [
      "m.room.create",
      # "m.room.name",
      "m.room.avatar",
      # "m.room.topic",
      "m.room.join_rules",
      "m.room.canonical_alias",
      "m.room.encryption"
    ]
  end
end
