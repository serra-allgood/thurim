defmodule Thurim.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Thurim.{Events, Events.Event, Repo}
  alias Thurim.Rooms.{Room, RoomAlias}

  @domain Application.compile_env(:thurim, [:matrix, :domain])

  def generate_room_id do
    "!" <> UUID.uuid4() <> ":" <> @domain
  end

  def valid_alias?(room_alias) do
    [head | _domain] = String.split(room_alias, ":", parts: 2)
    String.starts_with?(head, "#")
  end

  def our_domain?(room_alias) do
    domain = String.split(room_alias, ":", parts: 2) |> List.last()
    domain == @domain
  end

  def id_from_alias(room_alias) do
    name = extract_name_from_alias(room_alias)

    from(ra in RoomAlias, where: ra.alias == ^name, select: "room_id")
    |> Repo.one()
  end

  def extract_name_from_alias(room_alias) do
    [head | _tail] = String.split(room_alias, ":", parts: 2)
    "#" <> name = head
    name
  end

  def public_rooms(server, limit, since) do
    if is_nil(server) || server == @domain do
      offset =
        if !is_nil(limit) && !is_nil(since) do
          String.to_integer(limit) * String.to_integer(since)
        else
          0
        end

      membership_query =
        from(ev in Event,
          where: ev.type == "m.room.member",
          select: %{
            state_key: ev.state_key,
            membership:
              first_value(ev.content["membership"])
              |> over(
                partition_by: ev.state_key,
                order_by: [desc: ev.stream_ordering]
              ),
            room_id: ev.room_id
          }
        )

      query =
        from(r in Room,
          as: :rooms,
          join: e in Event,
          on: e.room_id == r.room_id,
          join: eve in Event,
          on: eve.room_id == r.room_id,
          join: ev in subquery(membership_query),
          on: ev.room_id == r.room_id,
          where: ev.membership == "join",
          where: e.content["join_rule"] == "public",
          group_by: r.id,
          select: %{
            room: r,
            event_content: fragment("array_agg(?)", eve.content),
            member_count: count(ev.state_key, :distinct)
          },
          order_by: [desc: count(ev.state_key, :distinct)]
        )

      result =
        if !is_nil(limit),
          do: query |> limit(^limit) |> offset(^offset) |> Repo.all(),
          else:
            query
            |> Repo.all()

      %{
        chunk: result |> Enum.map(&public_room_chunk/1),
        total_room_count_estimate: result |> length(),
        next_batch: offset
      }
    end
  end

  def public_room_chunk(%{room: room, member_count: member_count, event_content: event_content}) do
    IO.inspect(event_content)

    find_property = fn property ->
      content = event_content |> Enum.find(&(!is_nil(Map.get(&1, property))))
      if is_nil(content), do: nil, else: Map.fetch!(content, property)
    end

    %{
      guest_can_join: find_property.("guest_access") != "forbidden",
      num_joined_members: member_count,
      name: find_property.("name"),
      room_id: room.room_id,
      # TODO: Implement world_readable
      world_readable: false
    }
  end

  def all_user_rooms(mx_user_id) do
    from(r in Room,
      join: e in Event,
      on: e.room_id == r.room_id,
      where: e.state_key == ^mx_user_id,
      where: e.type == "m.room.member",
      group_by: r.id,
      select: {r, fragment("array_agg(?->>'membership')", e.content)}
    )
    |> Repo.all()
  end

  def user_rooms(mx_user_id, join_type \\ nil)

  def user_rooms(mx_user_id, join_type) when is_nil(join_type) do
    all_user_rooms(mx_user_id)
    |> Enum.filter(fn {_room, membership_events} ->
      !Enum.member?(~w(leave kick ban), List.last(membership_events))
    end)
    |> Enum.map(fn {room, _events} -> room end)
  end

  def user_rooms(mx_user_id, join_type) do
    all_user_rooms(mx_user_id)
    |> Enum.filter(fn {_room, membership_events} -> List.last(membership_events) == join_type end)
    |> Enum.map(fn {room, _events} -> room end)
  end

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  def create_room_alias(params \\ %{}) do
    %RoomAlias{}
    |> RoomAlias.changeset(Map.put(params, "creator_id", Map.fetch!(params, "sender")))
    |> Repo.insert()
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    attrs =
      Map.put(attrs, "room_id", generate_room_id())
      |> Map.put("creator_id", Map.fetch!(attrs, "sender"))

    multi =
      Multi.new()
      |> Multi.insert(:room, Room.changeset(%Room{}, attrs))
      |> Multi.run(:create_room_event, fn _repo, _changes ->
        Events.create_event(attrs, "m.room.create")
      end)
      |> Multi.run(:create_member_event, fn _repo, _changes ->
        attrs
        |> Map.put("event_state_key", Map.fetch!(attrs, "sender"))
        |> Events.create_event("m.room.member", "join")
      end)
      |> Multi.run(:create_power_levels, fn _repo, _changes ->
        Events.create_event(attrs, "m.room.power_levels")
      end)

    room_alias = Map.get(attrs, "room_alias_name", false)

    multi =
      if room_alias do
        multi
        |> Multi.run(:create_canonical_alias, fn _repo, _changes ->
          Events.create_event(attrs, "m.room.canonical_alias")
        end)
        |> Multi.insert(:create_alias, RoomAlias.changeset(%RoomAlias{alias: room_alias}, attrs))
      else
        multi
      end

    multi =
      case attrs["preset"] do
        "private_chat" ->
          multi
          |> Multi.run(:create_private_join_rule, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.join_rules", "invite")
          end)
          |> Multi.run(:create_history_visibility, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.history_visibility", "shared")
          end)
          |> Multi.run(:create_guest_access, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.guest_access", "can_join")
          end)

        "public_chat" ->
          multi
          |> Multi.run(:create_public_join_rule, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.join_rules", "public")
          end)
          |> Multi.run(:create_history_visibility, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.history_visibility", "shared")
          end)
          |> Multi.run(:create_guest_access, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.guest_access", "forbidden")
          end)

        "trusted_private_chat" ->
          multi
          |> Multi.run(:create_private_join_rule, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.join_rules", "invite")
          end)
          |> Multi.run(:create_history_visibility, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.history_visibility", "shared")
          end)
          |> Multi.run(:create_guest_access, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.guest_access", "can_join")
          end)

        _ ->
          multi
      end

    initial_state = Map.get(attrs, "initial_state", false)

    multi =
      if initial_state do
        Enum.with_index(initial_state, 7)
        |> Enum.reduce(multi, fn {state, index}, multi ->
          Multi.run(multi, "create_initial_state_#{index}", fn _repo, _changes ->
            Events.create_event(Map.merge(attrs, state), "initial_state")
          end)
        end)
      else
        multi
      end

    name = Map.get(attrs, "name", false)

    multi =
      if name do
        multi
        |> Multi.run(:create_name_event, fn _repo, _changes ->
          Events.create_event(attrs, "m.room.name")
        end)
      else
        multi
      end

    topic = Map.get(attrs, "topic", false)

    multi =
      if topic do
        multi
        |> Multi.run(:create_topic_event, fn _repo, _changes ->
          Events.create_event(attrs, "m.room.topic")
        end)
      else
        multi
      end

    invite = Map.get(attrs, "invite", false)

    multi =
      if invite do
        Enum.reduce(invite, multi, fn mx_user_id, multi ->
          Multi.run(multi, "create_invite_for_#{mx_user_id}", fn _repo_changes ->
            Events.create_event(
              Map.put(attrs, "state_key", mx_user_id),
              "m.room.membership",
              "invite"
            )
          end)
        end)
      else
        multi
      end

    Repo.transaction(multi)
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  alias Thurim.Rooms.RoomAlias

  @doc """
  Returns the list of room_aliases.

  ## Examples

      iex> list_room_aliases()
      [%RoomAlias{}, ...]

  """
  def list_room_aliases do
    Repo.all(RoomAlias)
  end

  @doc """
  Gets a single room_alias.

  Raises `Ecto.NoResultsError` if the Room alias does not exist.

  ## Examples

      iex> get_room_alias!(123)
      %RoomAlias{}

      iex> get_room_alias!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_alias!(id), do: Repo.get!(RoomAlias, id)

  @doc """
  Updates a room_alias.

  ## Examples

      iex> update_room_alias(room_alias, %{field: new_value})
      {:ok, %RoomAlias{}}

      iex> update_room_alias(room_alias, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room_alias(%RoomAlias{} = room_alias, attrs) do
    room_alias
    |> RoomAlias.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room_alias.

  ## Examples

      iex> delete_room_alias(room_alias)
      {:ok, %RoomAlias{}}

      iex> delete_room_alias(room_alias)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_alias(%RoomAlias{} = room_alias) do
    Repo.delete(room_alias)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_alias changes.

  ## Examples

      iex> change_room_alias(room_alias)
      %Ecto.Changeset{data: %RoomAlias{}}

  """
  def change_room_alias(%RoomAlias{} = room_alias, attrs \\ %{}) do
    RoomAlias.changeset(room_alias, attrs)
  end
end
