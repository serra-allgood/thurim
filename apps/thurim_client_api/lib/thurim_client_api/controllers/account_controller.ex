defmodule ThurimClientApi.AccountController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimiters.AccountController
       when action in ~w(add_threepid bind_threepid deactivate change_password whoami)a

  def add_threepid(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      errcode: "M_THREEPID_DENIED",
      error: "Third-party identifiers are not supported yet."
    })
  end

  def bind_threepid(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      errcode: "M_THREEPID_DENIED",
      error: "Third-party identifiers are not supported yet."
    })
  end

  def change_password(conn, %{"new_password" => new_password} = params) do
    current_user = Map.fetch!(conn.assigns, :current_user)
    current_device = Map.fetch!(conn.assigns, :current_device)
    logout_devices = Map.get(params, "logout_devices", true)

    case Accounts.update_password(new_password, current_user, current_device,
           logout_devices: logout_devices
         ) do
      {:ok, _changes} ->
        json(conn, %{})

      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          errcode: "THURIM_SURPRISE_ERROR",
          error: "This error should not have been reached."
        })
    end
  end

  def delete_threepid(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      errcode: "M_THREEPID_DENIED",
      error: "Third-party identifiers are not supported yet."
    })
  end

  # TODO: Automatic success as 3PIDs are not supported yet
  def deactivate(conn, _params) do
    json(conn, %{id_server_unbind_result: "success"})
  end

  def email(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{errcode: "M_THREEPID_DENIED", error: "Third-party identifier is not allowed."})
  end

  def msisdn(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{errcode: "M_THREEPID_DENIED", error: "Third-party identifier is not allowed."})
  end

  # TODO: Always returns an empty array as 3PIDs are not supported yet
  def threepid(conn, _params) do
    json(conn, %{threepids: []})
  end

  def threepid_email(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{errcode: "M_THREEPID_DENIED", error: "Third-party identifier is not allowed."})
  end

  def threepid_msisdn(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{errcode: "M_THREEPID_DENIED", error: "Third-party identifier is not allowed."})
  end

  def unbind_threepid(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{errcode: "M_THREEPID_DENIED", error: "Third-party identifier is not allowed."})
  end

  def whoami(conn, _params) do
    current_user = Map.fetch!(conn.assigns, :current_user)
    current_device = Map.fetch!(conn.assigns, :current_device)

    json(conn, %{
      # TODO: Guest users are not supported yet, so always false
      is_guest: false,
      user_id: current_user.user_id,
      device_id: current_device.device_id
    })
  end
end
