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
    sender = Map.get(conn.assigns, :sender)

    filter =
      case Map.fetch(params, "filter") do
        {:ok, filter_id} -> Filters.get_by(id: filter_id, localpart: account.localpart)
        :error -> nil
      end

    timeout = Map.get(params, "timeout", "0") |> String.to_integer()

    case SyncServer.build_sync(sender, device, filter, timeout, params) do
      :error ->
        json_error(conn, :m_unknown_error)

      response ->
        json(conn, response)
    end
  end
end
