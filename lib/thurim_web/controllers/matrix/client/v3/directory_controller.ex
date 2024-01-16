defmodule ThurimWeb.Matrix.Client.V3.DirectoryController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.Rooms

  @domain Application.compile_env(:thurim, [:matrix, :domain])

  def room_alias(conn, %{"room_alias" => room_alias} = _params) do
    if Rooms.valid_alias?(room_alias) do
      if Rooms.our_domain?(room_alias) do
        room_id = Rooms.id_from_alias(room_alias)

        if is_nil(room_id) do
          json_error(conn, :m_not_found)
        else
          # TODO: Get a list of servers that know the room
          json(conn, %{room_id: room_id, servers: [@domain]})
        end
      else
        json_error(conn, :t_not_implemented)
      end
    else
      json_error(conn, :m_invalid_param)
    end
  end
end
