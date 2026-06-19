defmodule ThurimCore.Accounts do
  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias ThurimCore.{
    Accounts.AccessToken,
    Accounts.Device,
    Accounts.RefreshToken,
    Accounts.User,
    Repo
  }

  @matrix_config Application.compile_env(:thurim_core, :matrix)
  @domain @matrix_config[:domain]
  @max_token_age @matrix_config[:max_token_age]

  def authenticate_user(user_id, password) do
    with user when not is_nil(user) <- get_user(user_id),
         password_hash when not is_nil(password_hash) <- user.password,
         true <- Argon2.verify_pass(password, password_hash) do
      {:ok, user}
    else
      _ -> {:error, :invalid_login}
    end
  end

  def create_access_token(user, device, refresh_token) do
    AccessToken.changeset(%AccessToken{}, %{
      user_id: user.user_id,
      device_id: device.device_id,
      refresh_token: refresh_token.token
    })
    |> Repo.insert()
  end

  def create_and_sign_access_token(user, device, refresh_token) do
    with {:ok, access_token} <- create_access_token(user, device, refresh_token),
         signed_access_token <-
           sign_access_token(access_token) do
      {:ok, signed_access_token}
    else
      {:error, error} -> {:error, error}
    end
  end

  def create_device(user_id, device_id, device_display_name) do
    %Device{user_id: user_id, device_id: device_id, display_name: device_display_name}
    |> Device.changeset(%{})
    |> Repo.insert()
  end

  def find_or_create_device(user_id, device_id, device_display_name) do
    case Repo.get(Device, [user_id, device_id]) do
      nil ->
        create_device(user_id, device_id, device_display_name)

      device ->
        {:ok, device}
    end
  end

  def generate_device_display_name(conn) do
    ua =
      conn
      |> Plug.Conn.get_req_header("user-agent")
      |> List.first()
      |> UAParser.parse()

    "#{ua} on #{ua.os}/#{ua.device}"
  end

  def generate_device_id() do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  def generate_refresh_token(user_id) do
    Phoenix.Token.sign(ThurimGateway.Endpoint, "refresh_token", user_id, max_age: @max_token_age)
  end

  def generate_user_localpart() do
    UUID.uuid4(:hex)
  end

  def get_access_token_by_refresh_token(refresh_token) do
    case Repo.get_by(AccessToken, refresh_token: refresh_token) do
      nil ->
        nil

      access_token ->
        Repo.preload(access_token, [:device, :user])
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

  def login(user_id, password, device_id, device_display_name) do
    Multi.new()
    |> Multi.run(:user, fn _repo, _changes ->
      authenticate_user(user_id, password)
    end)
    |> setup_device_and_tokens(device_id, device_display_name)
    |> Repo.transact()
  end

  def logout(device) do
    Repo.delete(device, allow_stale: true)
  end

  def logout_all(user) do
    from(d in Device, where: d.user_id == ^user.user_id)
    |> Repo.delete_all()
  end

  def mx_user_id(localpart) do
    "@" <> localpart <> ":" <> @domain
  end

  def new_refresh_token_changeset(user, device) do
    %RefreshToken{}
    |> RefreshToken.changeset(%{
      user_id: user.user_id,
      device_id: device.device_id,
      token: generate_refresh_token(user.user_id)
    })
  end

  def normalize_username("@" <> _rest = username), do: username
  def normalize_username(username), do: mx_user_id(username)

  def refresh_access_token(access_token) do
    Multi.new()
    |> Multi.insert(
      :refresh_token,
      new_refresh_token_changeset(access_token.user, access_token.device)
    )
    |> Multi.insert(:signed_access_token, fn %{refresh_token: refresh_token} ->
      create_and_sign_access_token(access_token.user, access_token.device, refresh_token)
    end)
    |> Repo.transact()
  end

  def register(params) do
    Multi.new()
    |> Multi.insert(:user, User.registration_changeset(%User{}, params))
    |> setup_device_and_tokens(params.device_id, params.device_display_name)
    |> Repo.transact()
  end

  defp setup_device_and_tokens(%Multi{} = multi, device_id, device_display_name) do
    multi
    |> Multi.run(:device, fn _repo, %{user: user} ->
      find_or_create_device(user.user_id, device_id, device_display_name)
    end)
    |> Multi.insert(:refresh_token, fn %{user: user, device: device} ->
      new_refresh_token_changeset(user, device)
    end)
    |> Multi.run(:signed_access_token, fn _repo,
                                          %{
                                            user: user,
                                            device: device,
                                            refresh_token: refresh_token
                                          } ->
      create_and_sign_access_token(user, device, refresh_token)
    end)
  end

  def sign_access_token(%AccessToken{} = access_token) do
    Phoenix.Token.sign(ThurimGateway.Endpoint, "access_token", access_token.id,
      max_age: @max_token_age
    )
  end

  def token_expires_in_ms(%AccessToken{} = token) do
    token.valid_until_ts
    |> DateTime.diff(DateTime.utc_now(:millisecond), :millisecond)
  end

  def username_available?(username) do
    is_taken =
      from(u in User, where: u.localpart == ^username)
      |> Repo.exists?()

    !is_taken
  end

  def verify_signed_access_token(signed_access_token) do
    with {:ok, access_token_id} <-
           Phoenix.Token.verify(ThurimGateway.Endpoint, "access_token", signed_access_token,
             max_age: @max_token_age
           ),
         access_token when not is_nil(access_token) <-
           get_access_token_with_preloads(access_token_id) do
      {:ok, access_token}
    else
      _ -> {:error, :unknown_token}
    end
  end

  def verify_signed_refresh_token(signed_refresh_token) do
    with {:ok, refresh_token_id} <-
           Phoenix.Token.verify(ThurimGateway.Endpoint, "refresh_token", signed_refresh_token),
         old_access_token when not is_nil(old_access_token) <-
           get_access_token_by_refresh_token(refresh_token_id),
         {:ok, %{signed_access_token: _access_token, refresh_token: _refresh_token} = changes} <-
           refresh_access_token(old_access_token) do
      {:ok, changes}
    else
      _ -> {:error, :unknown_token}
    end
  end
end
