defmodule Thurim.AccountData do
  @moduledoc """
  The AccountDatas context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.AccountData.AccountDatum

  @default_push_rules %{"global" => %{
    "content" => [],
    "override" => [],
    "room" => [],
    "sender" => [],
    "underride" => []
  }}

  @doc """
  Returns the list of account_data.

  ## Examples

      iex> list_account_data()
      [%AccountDatum{}, ...]

  """
  def list_account_data do
    Repo.all(AccountDatum)
  end

  @doc """
  Gets a single account_datum.

  Raises `Ecto.NoResultsError` if the Account datum does not exist.

  ## Examples

      iex> get_account_datum!(123)
      %AccountDatum{}

      iex> get_account_datum!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account_datum!(id), do: Repo.get!(AccountDatum, id)

  @doc """
  Creates a account_datum.

  ## Examples

      iex> create_account_datum(%{field: value})
      {:ok, %AccountDatum{}}

      iex> create_account_datum(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account_datum(attrs \\ %{}) do
    %AccountDatum{}
    |> AccountDatum.changeset(attrs)
    |> Repo.insert()
  end

  def create_push_rules(attrs \\ %{}) do
    %AccountDatum{type: "m.default_push_rules", content: @default_push_rules}
    |> AccountDatum.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account_datum.

  ## Examples

      iex> update_account_datum(account_datum, %{field: new_value})
      {:ok, %AccountDatum{}}

      iex> update_account_datum(account_datum, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account_datum(%AccountDatum{} = account_datum, attrs) do
    account_datum
    |> AccountDatum.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account_datum.

  ## Examples

      iex> delete_account_datum(account_datum)
      {:ok, %AccountDatum{}}

      iex> delete_account_datum(account_datum)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account_datum(%AccountDatum{} = account_datum) do
    Repo.delete(account_datum)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account_datum changes.

  ## Examples

      iex> change_account_datum(account_datum)
      %Ecto.Changeset{data: %AccountDatum{}}

  """
  def change_account_datum(%AccountDatum{} = account_datum, attrs \\ %{}) do
    AccountDatum.changeset(account_datum, attrs)
  end
end
