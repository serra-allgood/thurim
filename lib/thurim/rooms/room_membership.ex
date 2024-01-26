defmodule Thurim.Rooms.RoomMembership do
  @moduledoc """
  Functions related to a user's membership in rooms
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo
  alias Thurim.Events
  alias Thurim.Events.Event

  def user_ids_in_room(room) do
    from(
      e in Event,
      where: e.room_id == ^room.room_id,
      where: e.type == "m.room.member",
      group_by: [e.state_key],
      select: {e.state_key, fragment("array_agg(content->>'membership')")}
    )
    |> Repo.all()
    |> Enum.map(fn {user_id, memberships} -> {user_id, List.last(memberships)} end)
  end

  def membership_events_in_room(room_id, membership, not_membership, at_time) do
    join_types = ~w(join invite knock leave ban)

    base =
      from(e in Event,
        where:
          e.room_id == ^room_id and e.type == "m.room.member" and e.origin_server_ts < ^at_time,
        order_by: e.origin_server_ts
      )

    cond do
      not_membership != nil ->
        from(e in base,
          where:
            fragment("content->>'membership'") not in ^Enum.filter(
              join_types,
              &(&1 != not_membership)
            )
        )

      membership != nil ->
        from(e in base, where: fragment("content->>'membership'") == ^membership)

      true ->
        base
    end
    |> Repo.all()
  end

  def joined_user_ids_in_room(room_id) do
    from(e in Event,
      where: e.room_id == ^room_id and e.type == "m.room.member",
      where: e.content["membership"] == "join",
      select: {e.state_key, e.content["displayname"], e.content["avatar_url"]},
      order_by: e.origin_server_ts
    )
    |> Repo.all()
    |> Enum.group_by(
      fn {user_id, _displayname, _avatar_url} -> user_id end,
      fn {_user_id, displayname, avatar_url} ->
        %{"displayname" => displayname, "avatar_url" => avatar_url}
      end
    )
  end

  def in_room?(sender, room_id) do
    Events.latest_membership_type(room_id, sender) == "join"
  end

  def previously_in_room?(sender, room_id) do
    Events.user_previously_in_room?(sender, room_id)
  end

  def can_join?(sender, room_id) do
    Events.latest_membership_type(room_id, sender) != "ban"
  end
end
