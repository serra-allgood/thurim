defmodule ThurimWeb.Matrix.Client.V3.CapabilitiesController do
  require Logger
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  def index(conn, _params) do
    json(conn, %{
      "m.change_password" => %{
        "enabled" => true
      },
      "m.room_versions" => %{
        "available" => %{
          "9" => "stable"
        },
        "default" => "9"
      }
    })
  end
end
