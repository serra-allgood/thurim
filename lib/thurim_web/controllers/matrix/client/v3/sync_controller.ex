defmodule ThurimWeb.Matrix.Client.V3.SyncController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  # Shape of params:
  # {
  #   filter: string,
  #   full_state: boolean,
  #   set_presence: offline | online | unavailable,
  #   since: string,
  #   timeout: integer
  # }
  def index(conn, params) do
    %{current_device: device, current_account: account, sender: sender} = conn.assigns
    filter = Map.get(params, "filter") |> get_filter(account)
    timeout = Map.get(params, "timeout", "0") |> String.to_integer()
  end
end
