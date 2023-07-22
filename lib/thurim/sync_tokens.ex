defmodule Thurim.SyncTokens do
  @moduledoc """
  The SyncTokens context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.SyncTokens.SyncToken

  @doc """
  Returns the list of sync_tokens.

  ## Examples

      iex> list_sync_tokens()
      [%SyncToken{}, ...]

  """
  def list_sync_tokens do
    Repo.all(SyncToken)
  end

  @doc """
  Gets a single sync_token.

  Raises `Ecto.NoResultsError` if the Sync token does not exist.

  ## Examples

      iex> get_sync_token!(123)
      %SyncToken{}

      iex> get_sync_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sync_token!(id), do: Repo.get!(SyncToken, id)

  @doc """
  Creates a sync_token.

  ## Examples

      iex> create_sync_token(%{field: value})
      {:ok, %SyncToken{}}

      iex> create_sync_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sync_token(attrs \\ %{}) do
    %SyncToken{}
    |> SyncToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sync_token.

  ## Examples

      iex> update_sync_token(sync_token, %{field: new_value})
      {:ok, %SyncToken{}}

      iex> update_sync_token(sync_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sync_token(%SyncToken{} = sync_token, attrs) do
    sync_token
    |> SyncToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sync_token.

  ## Examples

      iex> delete_sync_token(sync_token)
      {:ok, %SyncToken{}}

      iex> delete_sync_token(sync_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sync_token(%SyncToken{} = sync_token) do
    Repo.delete(sync_token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sync_token changes.

  ## Examples

      iex> change_sync_token(sync_token)
      %Ecto.Changeset{data: %SyncToken{}}

  """
  def change_sync_token(%SyncToken{} = sync_token, attrs \\ %{}) do
    SyncToken.changeset(sync_token, attrs)
  end
end
