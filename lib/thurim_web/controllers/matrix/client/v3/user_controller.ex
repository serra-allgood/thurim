defmodule ThurimWeb.Matrix.Client.V3.UserController do
  require Logger
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.{AccessTokens, Devices, User, Utils}

  @matrix_config Application.compile_env(:thurim, :matrix)
  @flows @matrix_config[:auth_flow_types]
  @homeserver_url @matrix_config[:homeserver_url]
  @identity_server_url @matrix_config[:identity_server_url]
  @domain @matrix_config[:domain]

  def index(conn, _params) do
    render(conn, "index.json", flows: @flows)
  end

  # TODO: Fully implement the endpoint
  def show(conn, _params) do
    json(conn, %{})
  end

  def change_account_data(conn, %{"user_id" => user_id, "type" => type} = _params) do
    %{sender: sender} = conn.assigns

    cond do
      sender != user_id ->
        json_error(conn, :m_forbidden)

      User.account_data_exists?(user_id, type, "") ->
        case User.update_account_data(user_id, type, "", conn.body_params) do
          {:ok, _} ->
            json(conn, %{})

          {:error, changeset} ->
            Logger.error("Failed to update account_data: #{inspect(changeset, pretty: true)}")
            json_error(conn, :m_unknown)
        end

      true ->
        case User.create_account_data(user_id, type, "", conn.body_params) do
          {:ok, _} ->
            json(conn, %{})

          {:error, changeset} ->
            Logger.error("Failed to create account_data: #{inspect(changeset, pretty: true)}")
            json_error(conn, :m_unknown)
        end
    end
  end

  def whoami(conn, _params) do
    account = Map.get(conn.assigns, :current_account)

    json(conn, %{"user_id" => User.mx_user_id(account.localpart)})
  end

  def available(conn, %{"username" => username}) do
    json(conn, %{"available" => User.localpart_available?(username)})
  end

  def login(conn, params) do
    with %{"type" => login_type} when login_type == "m.login.password" <- params,
         %{"type" => identifier_type, "user" => localpart} when identifier_type == "m.id.user" <-
           params["identifier"],
         %{"password" => password} <- params,
         {:ok, account} <- User.authenticate(localpart, password) do
      device_display_name = Map.get(params, "initial_display_name", Utils.get_ua_repr(conn))
      device_id = Map.get(params, "device_id", Devices.generate_device_id(account.localpart))

      device =
        case Devices.get_by_device_id(device_id, account.localpart) do
          nil ->
            Devices.create_device_and_access_token(%{
              device_id: device_id,
              display_name: device_display_name,
              localpart: account.localpart,
              mx_user_id: "@#{localpart}:#{@domain}"
            })

          device ->
            device
        end

      signed_access_token = AccessTokens.get_signed_token(device.access_token.id)

      json(conn, %{
        device_id: device.device_id,
        user_id: User.mx_user_id(account.localpart),
        access_token: signed_access_token,
        well_known: %{
          "m.homeserver" => %{
            base_url: @homeserver_url
          },
          "m.identity_server" => %{
            base_url: @identity_server_url
          }
        }
      })
    else
      %{"type" => _} ->
        json_error(conn, :m_unknown)

      {:error, :invalid_login} ->
        json_error(conn, :m_forbidden)
    end
  end

  def logout(conn, _params) do
    Map.get(conn.assigns, :access_token)
    |> AccessTokens.delete_access_token()

    device = Map.get(conn.assigns, :current_device)
    Devices.delete_device(device)

    json(conn, %{})
  end

  def logout_all(conn, _params) do
    account = Map.get(conn.assigns, :current_account) |> User.preload_account()

    AccessTokens.delete_access_tokens(account.access_tokens)
    Devices.delete_devices(account.devices)

    json(conn, %{})
  end

  def password(conn, %{"new_password" => new_password} = params) do
    account = Map.get(conn.assigns, :current_account) |> User.preload_account()
    logout_devices = Map.get(params, "logout_devices", true)

    account |> User.update_account(%{"password" => new_password})

    if logout_devices do
      access_token = Map.get(conn.assigns, :access_token)
      device = Map.get(conn.assigns, :current_device)

      other_access_tokens =
        account.access_tokens
        |> Enum.filter(&(&1.id != access_token.id))

      other_devices =
        account.devices
        |> Enum.filter(&(&1.session_id != device.session_id))

      AccessTokens.delete_access_tokens(other_access_tokens)
      Devices.delete_devices(other_devices)
    end

    json(conn, %{})
  end

  def create(conn, params) do
    display_name = Map.get(params, "initial_display_name", Utils.get_ua_repr(conn))
    localpart = Map.get(params, "username", User.generate_localpart())
    device_id = Map.get(params, "device_id", Devices.generate_device_id(localpart))
    inhibit_login = Map.get(params, "inhibit_login", false)

    register_params =
      Map.merge(
        %{
          "display_name" => display_name,
          "localpart" => localpart,
          "inhibit_login" => inhibit_login,
          "device_id" => device_id,
          "server_name" => @domain
        },
        params
      )

    case User.register(register_params) do
      {:ok, %{account: account, device: device, signed_access_token: signed_access_token}} ->
        render(conn, "create.json",
          inhibit_login: register_params["inhibit_login"],
          account: account,
          device: device,
          signed_access_token: signed_access_token
        )

      {:error, _name, changeset, _changes} ->
        Logger.error("Failed to create user: #{inspect(changeset, pretty: true)}")
        send_changeset_error_to_json(conn, changeset)
    end
  end

  def push_rules(conn, _params) do
    account = Map.get(conn.assigns, :current_account)
    account_data = User.get_push_rules(account.localpart)
    push_rules = account_data.content

    json(conn, push_rules)
  end
end
