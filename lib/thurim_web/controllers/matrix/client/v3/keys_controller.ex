defmodule ThurimWeb.Matrix.Client.V3.KeysController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.{DeviceKeys, Rooms.RoomMembership}

  def query(conn, _params) do
    json(conn, %{})
  end

  def upload(conn, %{"device_keys" => %{"user_id" => mx_user_id} = device_keys} = params) do
    %{current_device: current_device, sender: sender} = conn.assigns
    one_time_keys = Map.get(params, "one_time_keys")

    with {:sender_matches_user_id, true} <- {:sender_matches_user_id, sender == mx_user_id},
         {:ok, _} <- DeviceKeys.process_device_keys(device_keys),
         {:ok, counts} <- DeviceKeys.process_one_time_keys(current_device, one_time_keys) do
      json(conn, counts)
    else
      {:sender_matches_user_id, false} ->
        json_error(conn, :m_forbidden)

      {:error, error} ->
        json_error(conn, error)
    end
  end

  def upload(conn, params) do
    %{current_device: current_device} = conn.assigns
    one_time_keys = Map.get(params, "one_time_keys")

    case DeviceKeys.process_one_time_keys(current_device, one_time_keys) do
      {:ok, counts} ->
        json(conn, counts)

      _ ->
        json_error(conn, :m_unknown)
    end
  end

  def changes(conn, %{"from" => from, "to" => to} = _params) do
    %{sender: sender} = conn.assigns
    device_changes = RoomMembership.get_device_changes(sender, from, to)
    json(conn, device_changes)
  end

  def changes(conn, _params) do
    json_error(conn, :m_missing_param)
  end
end
