defmodule Thurim.Snapshots do
  @moduledoc """
  The Snapshots context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.Snapshots.Snapshot

  @doc """
  Returns the list of snapshots.

  ## Examples

      iex> list_snapshots()
      [%Snapshot{}, ...]

  """
  def list_snapshots do
    Repo.all(Snapshot)
  end

  @doc """
  Gets a single snapshot.

  Raises `Ecto.NoResultsError` if the Snapshot does not exist.

  ## Examples

      iex> get_snapshot!(123)
      %Snapshot{}

      iex> get_snapshot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_snapshot!(id), do: Repo.get!(Snapshot, id)

  @doc """
  Creates a snapshot.

  ## Examples

      iex> create_snapshot(%{field: value})
      {:ok, %Snapshot{}}

      iex> create_snapshot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_snapshot(attrs \\ %{}) do
    %Snapshot{}
    |> Snapshot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a snapshot.

  ## Examples

      iex> update_snapshot(snapshot, %{field: new_value})
      {:ok, %Snapshot{}}

      iex> update_snapshot(snapshot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_snapshot(%Snapshot{} = snapshot, attrs) do
    snapshot
    |> Snapshot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a snapshot.

  ## Examples

      iex> delete_snapshot(snapshot)
      {:ok, %Snapshot{}}

      iex> delete_snapshot(snapshot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_snapshot(%Snapshot{} = snapshot) do
    Repo.delete(snapshot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking snapshot changes.

  ## Examples

      iex> change_snapshot(snapshot)
      %Ecto.Changeset{data: %Snapshot{}}

  """
  def change_snapshot(%Snapshot{} = snapshot, attrs \\ %{}) do
    Snapshot.changeset(snapshot, attrs)
  end
end
