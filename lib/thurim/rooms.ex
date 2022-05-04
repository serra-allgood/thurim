defmodule Thurim.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Thurim.Repo
  alias Thurim.Rooms.Room
  alias Thurim.Events

  @domain Application.get_env(:thurim, :matrix)[:domain]

  def generate_room_id() do
    "!" <> UUID.uuid4() <> ":" <> @domain
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

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    attrs = Map.put(attrs, "room_id", generate_room_id())

    multi =
      Multi.new()
      |> Multi.insert(:room, Room.changeset(%Room{}, attrs))
      |> Multi.run(:create_room_event, fn _repo, _changes ->
        Events.create_event(attrs, "m.room.create")
      end)
      |> Multi.run(:create_member_event, fn _repo, _changes ->
        attrs
        |> Map.put("event_state_key", Map.fetch!(attrs, "sender"))
        |> Events.create_event("m.room.member", "join", 2)
      end)
      |> Multi.run(:create_power_levels, fn _repo, _changes ->
        Events.create_event(attrs, "m.room.power_levels", 3)
      end)

    # TODO: Implement canonical room alias
    # if Map.get(attrs, "room_alias_name", false) do
    #   multi = multi |> Multi.run(:create_canonical_alias, fn _repo, _changes -> Events.create_event(attrs, "m.room.canonical_alias") end)
    # end

    multi =
      case Map.get(attrs, "preset", false) do
        "private_chat" ->
          multi
          |> Multi.run(:create_private_join_rule, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.join_rules", "invite", 4)
          end)
          |> Multi.run(:create_history_visibility, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.history_visibility", "shared", 5)
          end)
          |> Multi.run(:create_guest_access, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.guest_access", "can_join", 6)
          end)

        "public_chat" ->
          multi
          |> Multi.run(:create_public_join_rule, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.join_rules", "public", 4)
          end)
          |> Multi.run(:create_history_visibility, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.history_visibility", "shared", 5)
          end)
          |> Multi.run(:create_guest_access, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.guest_access", "forbidden", 6)
          end)

        "trusted_private_chat" ->
          multi
          |> Multi.run(:create_private_join_rule, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.join_rules", "invite", 4)
          end)
          |> Multi.run(:create_history_visibility, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.history_visibility", "shared", 5)
          end)
          |> Multi.run(:create_guest_access, fn _repo, _changes ->
            Events.create_event(attrs, "m.room.guest_access", "can_join", 6)
          end)

        _ ->
          multi
      end

    initial_state = Map.get(attrs, "initial_state", false)

    multi =
      if initial_state do
        Enum.with_index(initial_state, 6)
        |> Enum.reduce(multi, fn {state, index}, multi ->
          Multi.run(multi, :create_initial_state, fn _repo, _changes ->
            Events.create_event(state, "initial_state", index)
          end)
        end)
      else
        multi
      end

    # TODO: Events implied by m.room.name, m.room.topic, and invites

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
  Creates a room_alias.

  ## Examples

      iex> create_room_alias(%{field: value})
      {:ok, %RoomAlias{}}

      iex> create_room_alias(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room_alias(attrs \\ %{}) do
    %RoomAlias{}
    |> RoomAlias.changeset(attrs)
    |> Repo.insert()
  end

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
