defmodule ThurimWeb.Matrix.Client.V3.ReceiptController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  # TODO: Implement read receipts
  def create(
        conn,
        %{"room_id" => _room_id, "receipt_type" => receipt_type, "event_id" => _event_id} = params
      ) do
    %{sender: _sender} = conn.assigns
    _thread_id = Map.get(params, "thread_id", "main")

    if receipt_type == "m.fully_read" do
      fully_read(conn, params)
    else
      json(conn, %{})
    end
  end

  # TODO: Implement fully read marker
  def fully_read(conn, _params) do
    json(conn, %{})
  end
end
