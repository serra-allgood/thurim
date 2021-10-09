defmodule ThurimWeb.Matrix.Client.R0.PresenceController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.User
  alias Thurim.Presence

  def update(conn, params) do
    account = Map.get(conn.assigns, :current_account)

    if User.mx_user_id(account.localpart) == params["user_id"] do
      Presence.set_user_presence(params["user_id"], params["presence"], params["status_msg"])
      json(conn, %{})
    else
      json_error(conn, :m_forbidden)
    end
  end
end
