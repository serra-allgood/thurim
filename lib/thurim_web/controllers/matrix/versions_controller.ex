defmodule ThurimWeb.Matrix.VersionsController do
  use ThurimWeb, :controller

  def client(conn, _params) do
    json(conn, %{versions: ["v1.2", "v1.7"]})
  end
end
