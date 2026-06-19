defmodule ThurimClientApi.RegistrationController do
  use ThurimClientApi, :controller
  alias ThurimCore.Accounts

  plug ThurimClientApi.Plugs.RateLimiters.RegistrationController
       when action in ~w(available register)a

  def auth_metadata(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{errcode: "M_UNRECOGNIZED", error: "OAuth 2.0 not supported"})
  end

  def available(conn, %{"username" => username}) do
    json(conn, %{avaialble: Accounts.username_available?(username)})
  end

  def email(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def msisdn(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def register(conn, %{"kind" => "guest"}) do
    json_error(conn, :m_guest_access_forbidden)
  end

  def register(conn, params) do
    device_id = Map.get(params, "device_id", Accounts.generate_device_id())
    inhibit_login = Map.get(params, "inhibit_login", false)

    initial_device_display_name =
      Map.get(params, "initial_device_display_name", Accounts.generate_device_display_name(conn))

    password = Map.get(params, "password", nil)
    localpart = Map.get(params, "username", Accounts.generate_user_localpart())

    %{
      device_id: device_id,
      device_display_name: initial_device_display_name,
      password: password,
      localpart: localpart,
      user_id: Accounts.mx_user_id(localpart)
    }
    |> Accounts.register()
    |> case do
      {:ok, changes} ->
        json(conn, register_response(changes, inhibit_login))

      {:error, _failed_operation, _changeset, _changes_so_far} ->
        # TODO: Need to make this error response more descriptive
        json_error(conn, :m_unknow)
    end
  end

  defp register_response(changes, true = _inhibit_login) do
    %{user_id: changes.user.user_id}
  end

  defp register_response(changes, false = _inhibit_login) do
    %{
      access_token: changes.signed_access_token,
      expires_in_ms: Accounts.token_expires_in_ms(changes.access_token),
      refresh_token: changes.refresh_token,
      user_id: changes.user.user_id,
      device_id: changes.device.device_id
    }
  end
end
