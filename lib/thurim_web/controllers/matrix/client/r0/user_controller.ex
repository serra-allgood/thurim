defmodule ThurimWeb.Matrix.Client.R0.UserController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.User
  alias Thurim.Utils
  alias Thurim.Devices
  alias Thurim.AccessTokens

  @matrix_config Application.get_env(:thurim, :matrix)
  @flows @matrix_config[:auth_flows]
  @homeserver_url @matrix_config[:homeserver_url]
  @identity_server_url @matrix_config[:identity_server_url]

  def index(conn, _params) do
    render(conn, "index.json", flows: @flows)
  end

  def login(conn, params) do
    with %{"type" => login_type} when login_type == "m.login.password" <- params,
         %{"type" => identifier_type, "user" => localpart} when identifier_type == "m.id.user" <- params["identifier"],
         %{"password" => password} <- params,
         {:ok, account} <- User.authenticate(localpart, password) do
      device_display_name = Map.get(params, "initial_display_name", Utils.get_ua_repr(conn))
      device_id = Map.get(params, "device_id", Devices.generate_device_id())

      device =
        case Devices.get_by_device_id(device_id) do
          nil ->
            Devices.create_device_and_access_token(%{
              device_id: device_id,
              display_name: device_display_name,
              localpart: account.localpart
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

  def create(conn, params) do
    display_name = Map.get(params, "initial_display_name", Utils.get_ua_repr(conn))
    device_id = Map.get(params, "device_id", Devices.generate_device_id())
    localpart = Map.get(params, "username", User.generate_localpart())
    inhibit_login = Map.get(params, "inhibit_login", false)

    register_params =
      Map.merge(
        %{
          "display_name" => display_name,
          "localpart" => localpart,
          "inhibit_login" => inhibit_login,
          "device_id" => device_id
        },
        params
      )

    case User.register(register_params) do
      {:ok, account, device, signed_access_token} ->
        render(conn, "create.json",
          inhibit_login: register_params["inhibit_login"],
          account: account,
          device: device,
          signed_access_token: signed_access_token
        )

      {:error, errors} ->
        send_changeset_error_to_json(conn, errors)
    end
  end
end
