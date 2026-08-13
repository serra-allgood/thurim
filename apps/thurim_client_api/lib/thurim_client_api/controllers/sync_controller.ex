defmodule ThurimClientApi.SyncController do
  use ThurimClientApi, :controller
  alias ThurimCore.Sync

  def sync(conn, params) do
    current_user = Map.fetch!(conn.assigns, :current_user)
    current_device = conn.assigns[:current_device]

    case Sync.sync(current_user.user_id,
           since: params["since"],
           limit: params["limit"],
           timeout: params["timeout"],
           device_id: current_device && current_device.device_id
         ) do
      {:ok, response} ->
        json(conn, response)

      {:error, :invalid_since} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          errcode: "M_INVALID_PARAM",
          error: "The since token is invalid."
        })

      {:error, :invalid_limit} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          errcode: "M_INVALID_PARAM",
          error: "The limit parameter is invalid."
        })

      {:error, :invalid_timeout} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          errcode: "M_INVALID_PARAM",
          error: "The timeout parameter is invalid."
        })
    end
  end
end
