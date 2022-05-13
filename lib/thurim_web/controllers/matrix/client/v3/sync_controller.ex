defmodule ThurimWeb.Matrix.Client.V3.SyncController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.Sync.SyncServer
  alias Thurim.Filters

  # Shape of params:
  # {
  #   filter: string,
  #   full_state: boolean,
  #   set_presence: offline | online | unavailable,
  #   since: string,
  #   timeout: integer
  # }
  def index(conn, params) do
    device = Map.get(conn.assigns, :current_device)
    account = Map.get(conn.assigns, :current_account)
    sender = Map.get(conn.assigns, :sender)

    filter =
      case Map.fetch(params, "filter") do
        {:ok, filter_id} -> Filters.get_by(id: filter_id, localpart: account.localpart)
        :error -> nil
      end

    if Map.get(params, "timeout", 0) == 0 do
      case SyncServer.build_sync(sender, device, filter, params) do
        {:ok, response} -> json(conn, response)
        :error -> json_error(conn, :m_unknown_error)
      end
    else
      json(conn, %{})
    end
  end
end
