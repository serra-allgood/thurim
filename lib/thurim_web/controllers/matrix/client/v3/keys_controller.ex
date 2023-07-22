defmodule ThurimWeb.Matrix.Client.V3.KeysController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  def query(conn, _params) do
    json(conn, %{})
  end

  def upload(conn, _params) do
    json(conn, %{})
  end
end
