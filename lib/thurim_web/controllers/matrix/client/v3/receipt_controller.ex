defmodule ThurimWeb.Matrix.Client.V3.ReceiptController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  # TODO: Implement read receipts
  def create(
        conn,
        %{"room_id" => room_id, "receipt_type" => receipt_type, "event_id" => event_id} = params
      ) do
    %{sender: sender} = conn.assigns
    thread_id = Map.get(params, "thread_id", "main")

    if receipt_type == "m.fully_read" do
      fully_read(conn, params)
    else
      json(conn, %{})
    end
  end

  # TODO: Implement fully read marker
  def fully_read(conn, params) do
    json(conn, %{})
  end
end
