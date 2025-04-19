defmodule ThurimWeb.Matrix.Client.V3.DeviceMessageController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.{DeviceMessages, Sync.SyncServer, Transactions}

  def send_message(
        conn,
        %{"event_type" => event_type, "txn_id" => txn_id, "messages" => messages} = _params
      ) do
    %{sender: sender, current_device: device, current_account: account} = conn.assigns

    txn =
      Transactions.get(
        localpart: account.localpart,
        device_id: device.device_id,
        transaction_id: txn_id
      )

    if !is_nil(txn) do
      json(conn, %{})
    else
      case Transactions.create_transaction(%{
             "localpart" => account.localpart,
             "device_id" => device.device_id,
             "transaction_id" => txn_id
           }) do
        {:ok, _} ->
          Enum.each(messages, fn {mx_user_id, devices} ->
            Enum.each(devices, fn {device_id, content} ->
              event_params = %{
                "sender" => sender,
                "content" => content,
                "type" => event_type,
                "mx_user_id" => mx_user_id
              }

              if device_id == "*" do
                DeviceMessages.send_to_all_devices(mx_user_id, event_params)
              else
                DeviceMessages.send_to_device(Map.put(event_params, "device_id", device_id))
              end
            end)
          end)

          SyncServer.notify_listeners()
          json(conn, %{})

        {:error, _} ->
          json_error(conn, :m_unknown_error)
      end
    end
  end
end
