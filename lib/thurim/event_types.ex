defmodule Thurim.EventTypes do
  @moduledoc """
  The EventTypes context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.EventTypes.EventType

  @doc """
  Returns the list of event_types.

  ## Examples

      iex> list_event_types()
      [%EventType{}, ...]

  """
  def list_event_types do
    Repo.all(EventType)
  end

  @doc """
  Gets a single event_type.

  Raises `Ecto.NoResultsError` if the Event type does not exist.

  ## Examples

      iex> get_event_type!(123)
      %EventType{}

      iex> get_event_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_type!(id), do: Repo.get!(EventType, id)

  @doc """
  Creates a event_type.

  ## Examples

      iex> create_event_type(%{field: value})
      {:ok, %EventType{}}

      iex> create_event_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_type(attrs \\ %{}) do
    %EventType{}
    |> EventType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_type.

  ## Examples

      iex> update_event_type(event_type, %{field: new_value})
      {:ok, %EventType{}}

      iex> update_event_type(event_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_type(%EventType{} = event_type, attrs) do
    event_type
    |> EventType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event_type.

  ## Examples

      iex> delete_event_type(event_type)
      {:ok, %EventType{}}

      iex> delete_event_type(event_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_type(%EventType{} = event_type) do
    Repo.delete(event_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_type changes.

  ## Examples

      iex> change_event_type(event_type)
      %Ecto.Changeset{data: %EventType{}}

  """
  def change_event_type(%EventType{} = event_type, attrs \\ %{}) do
    EventType.changeset(event_type, attrs)
  end
end
