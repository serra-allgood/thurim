defmodule Thurim.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.Events.EventStateKey

  @doc """
  Returns the list of event_state_keys.

  ## Examples

      iex> list_event_state_keys()
      [%EventStateKey{}, ...]

  """
  def list_event_state_keys do
    Repo.all(EventStateKey)
  end

  @doc """
  Gets a single event_state_key.

  Raises `Ecto.NoResultsError` if the Event state key does not exist.

  ## Examples

      iex> get_event_state_key!(123)
      %EventStateKey{}

      iex> get_event_state_key!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_state_key!(id), do: Repo.get!(EventStateKey, id)

  @doc """
  Creates a event_state_key.

  ## Examples

      iex> create_event_state_key(%{field: value})
      {:ok, %EventStateKey{}}

      iex> create_event_state_key(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_state_key(attrs \\ %{}) do
    %EventStateKey{}
    |> EventStateKey.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_state_key.

  ## Examples

      iex> update_event_state_key(event_state_key, %{field: new_value})
      {:ok, %EventStateKey{}}

      iex> update_event_state_key(event_state_key, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_state_key(%EventStateKey{} = event_state_key, attrs) do
    event_state_key
    |> EventStateKey.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event_state_key.

  ## Examples

      iex> delete_event_state_key(event_state_key)
      {:ok, %EventStateKey{}}

      iex> delete_event_state_key(event_state_key)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_state_key(%EventStateKey{} = event_state_key) do
    Repo.delete(event_state_key)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_state_key changes.

  ## Examples

      iex> change_event_state_key(event_state_key)
      %Ecto.Changeset{data: %EventStateKey{}}

  """
  def change_event_state_key(%EventStateKey{} = event_state_key, attrs \\ %{}) do
    EventStateKey.changeset(event_state_key, attrs)
  end

  alias Thurim.Events.StateSnapshot

  @doc """
  Returns the list of state_snapshots.

  ## Examples

      iex> list_state_snapshots()
      [%StateSnapshot{}, ...]

  """
  def list_state_snapshots do
    Repo.all(StateSnapshot)
  end

  @doc """
  Gets a single state_snapshot.

  Raises `Ecto.NoResultsError` if the State snapshot does not exist.

  ## Examples

      iex> get_state_snapshot!(123)
      %StateSnapshot{}

      iex> get_state_snapshot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_state_snapshot!(id), do: Repo.get!(StateSnapshot, id)

  @doc """
  Creates a state_snapshot.

  ## Examples

      iex> create_state_snapshot(%{field: value})
      {:ok, %StateSnapshot{}}

      iex> create_state_snapshot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_state_snapshot(attrs \\ %{}) do
    %StateSnapshot{}
    |> StateSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a state_snapshot.

  ## Examples

      iex> update_state_snapshot(state_snapshot, %{field: new_value})
      {:ok, %StateSnapshot{}}

      iex> update_state_snapshot(state_snapshot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_state_snapshot(%StateSnapshot{} = state_snapshot, attrs) do
    state_snapshot
    |> StateSnapshot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a state_snapshot.

  ## Examples

      iex> delete_state_snapshot(state_snapshot)
      {:ok, %StateSnapshot{}}

      iex> delete_state_snapshot(state_snapshot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_state_snapshot(%StateSnapshot{} = state_snapshot) do
    Repo.delete(state_snapshot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking state_snapshot changes.

  ## Examples

      iex> change_state_snapshot(state_snapshot)
      %Ecto.Changeset{data: %StateSnapshot{}}

  """
  def change_state_snapshot(%StateSnapshot{} = state_snapshot, attrs \\ %{}) do
    StateSnapshot.changeset(state_snapshot, attrs)
  end

  alias Thurim.Events.Event

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    Repo.all(Event)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  alias Thurim.Events.EventJson

  @doc """
  Returns the list of event_json.

  ## Examples

      iex> list_event_json()
      [%EventJson{}, ...]

  """
  def list_event_json do
    Repo.all(EventJson)
  end

  @doc """
  Gets a single event_json.

  Raises `Ecto.NoResultsError` if the Event json does not exist.

  ## Examples

      iex> get_event_json!(123)
      %EventJson{}

      iex> get_event_json!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_json!(id), do: Repo.get!(EventJson, id)

  @doc """
  Creates a event_json.

  ## Examples

      iex> create_event_json(%{field: value})
      {:ok, %EventJson{}}

      iex> create_event_json(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_json(attrs \\ %{}) do
    %EventJson{}
    |> EventJson.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_json.

  ## Examples

      iex> update_event_json(event_json, %{field: new_value})
      {:ok, %EventJson{}}

      iex> update_event_json(event_json, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_json(%EventJson{} = event_json, attrs) do
    event_json
    |> EventJson.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event_json.

  ## Examples

      iex> delete_event_json(event_json)
      {:ok, %EventJson{}}

      iex> delete_event_json(event_json)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_json(%EventJson{} = event_json) do
    Repo.delete(event_json)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_json changes.

  ## Examples

      iex> change_event_json(event_json)
      %Ecto.Changeset{data: %EventJson{}}

  """
  def change_event_json(%EventJson{} = event_json, attrs \\ %{}) do
    EventJson.changeset(event_json, attrs)
  end
end
