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

  @cache_ttl 60 * 60

  def get_signed_token(access_token_id) do
    case AccessTokenCache.get(access_token_id) || Repo.get(AccessToken, access_token_id) do
      nil ->
        nil

      access_token ->
        AccessTokenCache.set(access_token.id, Repo.preload(access_token, [:device, :account]),
          ttl: @cache_ttl
        )

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
      AccessTokenCache.set(access_token.id, access_token, ttl: @cache_ttl)
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
  def list_access_tokens do
    Repo.all(AccessToken)
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
