defmodule ThurimWeb.Matrix.Client.V3.KeysController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.{Keys, Rooms.RoomMembership}

  def backup(conn, %{"rooms" => room_keys} = _params) do
    %{current_account: current_account} = conn.assigns

    case Keys.backup_room_keys(room_keys, current_account) do
      {:ok, response} -> json(conn, response)
      :error -> json(conn, :m_unknown)
    end
  end

  def claim(conn, %{"one_time_keys" => one_time_keys} = _params) do
    case Keys.claim_one_time_keys(one_time_keys) do
      {:ok, response} -> json(conn, response)
      _ -> json_error(conn, :m_unknown)
    end
  end

  def show_version(conn, _params) do
    %{current_account: current_account} = conn.assigns

    if Keys.backup_exists?(current_account) do
      json(conn, Keys.show_version_response(current_account))
    else
      json_error(conn, :m_not_found)
    end
  end

  def get_keys(conn, _params) do
    %{current_account: current_account} = conn.assigns

    json(conn, Keys.get_keys(current_account))
  end

  def device_singing(conn, params) do
    %{sender: sender} = conn.assigns
    master_key = Map.get(params, "master_key")
    self_signing_key = Map.get(params, "self_signing_key")
    user_signing_key = Map.get(params, "user_signing_key")

    with {:ok, _} <- Keys.process_cross_signing_key(sender, master_key),
         {:ok, _} <- Keys.process_cross_signing_key(sender, self_signing_key),
         {:ok, _} <- Keys.process_cross_signing_key(sender, user_signing_key) do
      json(conn, %{})
    else
      {:error, _} -> json_error(conn, :m_unknown)
    end
  end

  # TODO: Implement lookup via federation with timeout
  def query(conn, %{"device_keys" => device_key_query} = _params) do
    device_keys = Keys.query_keys(device_key_query)
    json(conn, device_keys)
  end

  def upload(conn, %{"device_keys" => %{"user_id" => mx_user_id} = device_keys} = params) do
    %{current_device: current_device, sender: sender} = conn.assigns
    one_time_keys = Map.get(params, "one_time_keys")

    with {:sender_matches_user_id, true} <- {:sender_matches_user_id, sender == mx_user_id},
         {:ok, _} <- Keys.process_device_keys(device_keys),
         {:ok, counts} <- Keys.process_one_time_keys(current_device, one_time_keys) do
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

    case Keys.process_one_time_keys(current_device, one_time_keys) do
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
