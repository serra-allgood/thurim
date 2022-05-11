defmodule ThurimWeb.Matrix.Client.R0.SyncController do
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

    filter =
      case Map.fetch(params, "filter") do
        {:ok, filter_id} -> Filters.get_by(id: filter_id, localpart: account.localpart)
        :error -> nil
      end

    if Map.get(params, "full_state", false) || Map.get(params, "timeout", 0) == 0 do
      case SyncServer.build_sync(account, device, filter, params) do
        {:ok, response} -> json(conn, response)
        :error -> json_error(conn, :m_unknown_error)
      end
    else
      json(conn, %{})
    end
  end
end
