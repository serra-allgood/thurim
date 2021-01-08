defmodule ThurimWeb.Matrix.Client.R0.UserController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.User
  alias Thurim.Utils
  alias Thurim.Devices

  def index(conn, _params) do
    render(conn, "index.json")
  end

  def create(conn, params) do
    display_name = Map.get(params, "initial_display_name", Utils.get_ua_repr(conn))
    device_id = Map.get(params, "device_id", Devices.generate_device_id(Utils.get_ua(conn)))
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
