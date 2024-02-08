defmodule ThurimWeb.Matrix.Client.V3.KeysController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.Rooms.RoomMembership

  def query(conn, _params) do
    json(conn, %{})
  end

  def upload(conn, _params) do
    json(conn, %{})
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
