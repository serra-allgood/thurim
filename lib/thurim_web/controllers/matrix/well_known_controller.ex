defmodule ThurimWeb.Matrix.WellKnownController do
  use ThurimWeb, :controller

  @homeserver_url Application.get_env(:thurim, :matrix)[:homeserver_url]

  def client(conn, _params) do
    json(conn, %{
      "m.homeserver" => %{"base_url" => @homeserver_url},
      "m.identity_server" => %{"base_url" => "https://matrix.org"}
    })
  end
end
