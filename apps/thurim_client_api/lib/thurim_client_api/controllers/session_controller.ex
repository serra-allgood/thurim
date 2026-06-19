defmodule ThurimClientApi.SessionController do
  use ThurimClientApi, :controller
  alias ThurimCore.Accounts

  @matrix_config Application.compile_env(:thurim_core, :matrix)

  plug ThurimClientApi.Plugs.RateLimiters.SessionController
       when action in ~w(get_token login login_types refresh)a

  def get_token(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{errcode: "THURIM_NOT_SUPPORTED", error: "This endpoint is not supported."})
  end

  def login(
        conn,
        %{
          "type" => "m.login.password",
          "password" => password,
          "identifier" => %{"type" => "m.id.user", "user" => username}
        } = params
      ) do
    device_id = Map.get(params, "device_id", Accounts.generate_device_id())

    username
    |> Accounts.normalize_username()
    |> Accounts.login(password, device_id, Accounts.generate_device_display_name(conn))
    |> case do
      {:ok, changes} ->
        json(conn, %{
          access_token: changes.signed_access_token,
          expires_in_ms: Accounts.token_expires_in_ms(changes.signed_access_token),
          device_id: changes.device.device_id,
          user_id: changes.user.user_id,
          refresh_token: changes.refresh_token
        })

      {:error, _failed_opearation, _failed_value, _changes_so_far} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errcode: "M_BAD_JSON", error: "TODO: Descriptive error message"})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{errcode: "M_BAD_TYPE", error: "Login type not supported."})
  end

  def login_types(conn, _params) do
    json(conn, %{flows: @matrix_config[:auth_flow_types]})
  end

  def logout(conn, _params) do
    current_device = Map.fetch!(conn.assigns, :current_device)

    case Accounts.logout(current_device) do
      {:ok, _device} ->
        json(conn, %{})

      {:error, _error} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          errcode: "THURIM_SURPRISE_ERROR",
          error: "This error should not have been reached."
        })
    end
  end

  def logout_all(conn, _params) do
    current_user = Map.fetch!(conn.assigns, :current_user)

    case Accounts.logout_all(current_user) do
      {0, nil} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          errcode: "THURIM_SURPRISE_ERROR",
          error: "This error should not have been reached."
        })

      {count, nil} when is_integer(count) ->
        json(conn, %{})
    end
  end

  def refresh(conn, %{"refresh_token" => signed_refresh_token}) do
    case Accounts.verify_signed_refresh_token(signed_refresh_token) do
      {:ok, %{signed_access_token: access_token, refresh_token: refresh_token}} ->
        json(conn, %{
          access_token: access_token,
          expires_in_ms: Accounts.token_expires_in_ms(access_token),
          refresh_token: refresh_token
        })

      {:error, :unknown_token} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errcode: "M_UNKNOWN_TOKEN", error: "TODO: Descriptive error message."})
    end
  end
end
