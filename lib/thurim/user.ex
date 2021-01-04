defmodule Thurim.User do
  @moduledoc """
  The User context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.User.Account
  alias Thurim.Devices
  alias Thurim.Profiles
  alias Thurim.AccountData
  alias Thurim.AccessTokens

  def mx_user_id(localpart) do
    "@" <> localpart <> ":" <> ThurimWeb.Endpoint.config(:domain)
  end

  def generate_localpart() do
    UUID.uuid4() |> Base.hex_encode32(padding: false, case: :lower)
  end

  def authenticate(localpart, password) do
    with account when not is_nil(account) <- get_account(localpart),
         password_hash when not is_nil(password_hash) <- account.password_hash do
      if Bcrypt.verify_pass(password, password_hash) do
        {:ok, account}
      else
        {:error, :invalid_login}
      end
    else
      _ -> {:error, :not_found}
    end
  end

  def register(params) do
    with account <- Account.changeset(%Account{}, params),
         {:ok, account} <- Repo.insert(account),
         {:ok, device} <- Devices.create_device(params),
         {:ok, _} <- Profiles.create_profile(%{"localpart" => account.localpart}),
         {:ok, _} <- AccountData.create_push_rules(%{"localpart" => account.localpart}),
         {:ok, signed_access_token} <- AccessTokens.sign(device.session_id, account.localpart) do
      {:ok, account, signed_access_token}
    end
  end

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  def get_account(localpart), do: Repo.get(Account, localpart)

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(localpart), do: Repo.get!(Account, localpart)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end
end
