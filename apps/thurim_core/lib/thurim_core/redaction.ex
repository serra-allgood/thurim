defmodule ThurimCore.Redaction do
  @base_keys [
    "event_id",
    "type",
    "room_id",
    "sender",
    "state_key",
    "content",
    "hashes",
    "signatures",
    "depth",
    "prev_events",
    "auth_events",
    "origin_server_ts"
  ]

  def redact(event, room_version) do
    event
    |> Map.take(@base_keys)
    |> redact_contact_key(room_version)
  end

  defp redact_contact_key(event, _room_version) do
    event
    |> Map.update!("content", fn content ->
      case event["type"] do
        "m.room.member" ->
          Map.take(content, ~w(membership join_authorised_via_users_server))

        "m.room.create" ->
          content

        "m.room.join_rules" ->
          Map.take(content, ~w(join_rule allow))

        "m.room.power_levels" ->
          Map.take(
            content,
            ~w(ban events events_default invite kick redact state_default users users_default)
          )

        "m.room.history_visibility" ->
          Map.take(content, ["history_visibility"])

        "m.room.redaction" ->
          Map.take(content, ["redacts"])

        # Any other type drops all keys
        _ ->
          %{}
      end
    end)
  end
end
