defmodule ThurimWeb.Matrix.VersionsController do
  use ThurimWeb, :controller

  def client(conn, _params) do
    render(conn, "client.json")
  end
end
