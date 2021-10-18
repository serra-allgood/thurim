defmodule ThurimWeb.Matrix.Client.R0.SyncController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.Sync

  def index(conn, params) do
    device = Map.get(conn.assigns, :current_device)
    account = Map.get(conn.assigns, :current_account)

    case Sync.SyncHandler.get_updates(account, device, params) do
      {:ok, result} -> json(conn, result)
      {:error, errcode} -> json_error(conn, errcode)
    end
  end
end
