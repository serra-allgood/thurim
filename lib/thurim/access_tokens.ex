defmodule Thurim.AccessTokens do
  @moduledoc """
  The AccessTokens context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo
  alias Thurim.AccessTokens.AccessToken
  alias Thurim.AccessTokens.AccessTokenCache
  alias Phoenix.Token
  alias Thurim.Repo

  def get_signed_token(access_token_id) do
    case AccessTokenCache.get(access_token_id) || Repo.get(AccessToken, access_token_id) do
      nil ->
        nil

      access_token ->
        AccessTokenCache.put(access_token.id, Repo.preload(access_token, [:device, :account]))

        sign(access_token)
    end
  end

  def sign(access_token) do
    Token.sign(ThurimWeb.Endpoint, "access token", access_token.id)
  end

  def create_and_sign(device_session_id, localpart) do
    with {:ok, access_token} <-
           create_access_token(%{device_session_id: device_session_id, localpart: localpart}),
         access_token <- Repo.preload(access_token, [:device, :account]),
         signed_access_token <- sign(access_token) do
      AccessTokenCache.put(access_token.id, access_token)
      {:ok, signed_access_token}
    end
  end

  def verify(signed_access_token) do
    with {:ok, access_token_id} <-
           Token.verify(ThurimWeb.Endpoint, "access token", signed_access_token),
         access_token when not is_nil(access_token) <-
           AccessTokenCache.get(access_token_id) ||
             get_access_token_with_preloads(access_token_id) do
      {:ok, access_token}
    else
      _ -> {:error, :unknown_token}
    end
  end

  @doc """
  Returns the list of access_tokens.

  ## Examples

      iex> list_access_tokens()
      [%AccessToken{}, ...]

  """
  def list_access_tokens(localpart) do
    from(a in AccessToken, where: a.localpart == ^localpart)
    |> Repo.all()
  end

  @doc """
  Gets a single access_token.

  Raises `Ecto.NoResultsError` if the Access token does not exist.

  ## Examples

      iex> get_access_token!(123)
      %AccessToken{}

      iex> get_access_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_access_token!(id), do: Repo.get!(AccessToken, id)

  def get_access_token_with_preloads(id) do
    case Repo.get(AccessToken, id) do
      nil ->
        nil

      access_token ->
        Repo.preload(access_token, [:device, :account])
    end
  end

  @doc """
  Creates a access_token.

  ## Examples

      iex> create_access_token(%{field: value})
      {:ok, %AccessToken{}}

      iex> create_access_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_access_token(attrs \\ %{}) do
    %AccessToken{}
    |> AccessToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a access_token.

  ## Examples

      iex> update_access_token(access_token, %{field: new_value})
      {:ok, %AccessToken{}}

      iex> update_access_token(access_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_access_token(%AccessToken{} = access_token, attrs) do
    access_token
    |> AccessToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a access_token.

  ## Examples

      iex> delete_access_token(access_token)
      {:ok, %AccessToken{}}

      iex> delete_access_token(access_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_access_token(%AccessToken{} = access_token) do
    AccessTokenCache.delete(access_token.id)
    Repo.delete(access_token)
  end

  def delete_access_tokens(access_tokens) do
    ids = access_tokens |> Enum.map(& &1.id)
    ids |> Enum.each(&AccessTokenCache.delete/1)

    from(a in AccessToken, where: a.id in ^ids)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking access_token changes.

  ## Examples

      iex> change_access_token(access_token)
      %Ecto.Changeset{data: %AccessToken{}}

  """
  def change_access_token(%AccessToken{} = access_token, attrs \\ %{}) do
    AccessToken.changeset(access_token, attrs)
  end
end
