defmodule Thurim.Rooms.RoomMembership do
  @moduledoc """
  Functions related to a user's membership in rooms
  """

  import Ecto.Query, warn: false
  alias Thurim.{Devices.Device, Events, Events.Event, Repo}

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
        where: e.room_id == ^room_id and e.type == "m.room.member" and e.pdu_count < ^at_time,
        order_by: e.pdu_count
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

  def get_device_changes(sender, from, to) do
    member_events =
      from(e in Event,
        where: e.type == "m.room.member",
        select: %{
          state_key: e.state_key,
          room_id: e.room_id,
          membership:
            first_value(fragment("?->>'membership'", e.content))
            |> over(
              partition_by: e.state_key,
              order_by: [desc: e.pdu_count]
            )
        }
      )

    encrypted_sender_rooms =
      from(e in subquery(member_events),
        as: :events,
        where: e.state_key == ^sender and e.membership == "join",
        where:
          exists(
            from(ev in Event,
              where: parent_as(:events).room_id == ev.room_id and ev.type == "m.room.encryption"
            )
          ),
        select: e.room_id
      )

    user_ids_in_shared_encrypted_rooms =
      from(e in Event,
        join: me in subquery(member_events),
        on: me.room_id == e.room_id,
        where: e.room_id in subquery(encrypted_sender_rooms),
        where: e.pdu_count > ^from and e.pdu_count <= ^to,
        where: me.state_key != ^sender and me.membership == "join",
        select: %{user_id: me.state_key}
      )

    user_ids_previously_in_shared_encrypted_rooms =
      from(e in Event,
        join: me in subquery(member_events),
        on: me.room_id == e.room_id,
        where: e.room_id in subquery(encrypted_sender_rooms),
        where: e.pdu_count > ^from and e.pdu_count <= ^to,
        where: me.state_key != ^sender and me.membership in ~w(leave kick ban),
        select: %{user_id: me.state_key}
      )

    from(dv in Device,
      left_join: c in subquery(user_ids_in_shared_encrypted_rooms),
      on: c.user_id == dv.mx_user_id,
      left_join: l in subquery(user_ids_previously_in_shared_encrypted_rooms),
      on: l.user_id == dv.mx_user_id,
      where: dv.version > ^from and dv.version <= ^to,
      select: %{
        changed: fragment("array_remove(array_agg(distinct ?), null)", c.user_id),
        left: fragment("array_remove(array_agg(distinct ?), null)", l.user_id)
      }
    )
    |> Repo.one()
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
