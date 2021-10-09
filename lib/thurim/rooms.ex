defmodule Thurim.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo
  alias Thurim.Rooms.Room

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
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
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
