defmodule ThurimWeb.Matrix.Client.R0.UserController do
  use ThurimWeb, :controller

  def index(conn, _params) do
    render(conn, "index.json")
  end

  def create(conn, _params) do
    json(conn, %{})
  end
end
