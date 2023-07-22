defmodule ThurimWeb.Matrix.Client.V3.PresenceController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.PresenceServer

  def show(conn, %{"user_id" => user_id}) do
    case PresenceServer.get_user_presence(user_id) do
      :error -> json_error(conn, :m_not_found)
      presence -> json(conn, presence)
    end
  end

  def update(conn, %{"user_id" => user_id} = params) do
    sender = Map.get(conn.assigns, :sender)
    device = Map.get(conn.assigns, :current_device)

    if sender == user_id do
      PresenceServer.set_user_presence(
        user_id,
        device.device_id,
        Map.get(params, "presence"),
        Map.get(params, "status_msg")
      )

      json(conn, %{})
    else
      json_error(conn, :m_forbidden)
    end
  end
end
