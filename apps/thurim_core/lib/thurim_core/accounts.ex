defmodule ThurimCore.Accounts do
  import Ecto.Query, warn: false
  alias ThurimCore.{Accounts.User, Tokens.AccessToken, Repo}

  def authenticate_user(user_id, password) do
    with user when not is_nil(user) <- get_user(user_id),
         password_hash when not is_nil(password_hash) <- user.password_hash,
         true <- Argon2.verify_pass(password, password_hash) do
      {:ok, user}
    else
      _ -> {:error, :invalid_login}
    end
  end

  def get_access_token_with_preloads(id) do
    case Repo.get(AccessToken, id) do
      nil ->
        nil

      access_token ->
        Repo.preload(access_token, [:device, :user])
    end
  end

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def verify_signed_access_token(signed_access_token) do
    with {:ok, access_token_id} <-
           Phoenix.Token.verify(ThurimGateway.Endpoint, "access_token", signed_access_token),
         access_token when not is_nil(access_token) <-
           get_access_token_with_preloads(access_token_id) do
      {:ok, access_token}
    else
      _ -> {:error, :unknown_token}
    end
  end
end
