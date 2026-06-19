defmodule ThurimGateway.WellKnownController do
  use ThurimGateway, :controller

  @matrix_config Application.compile_env(:thurim_core, :matrix)
  @homeserver_url @matrix_config[:homeserver_url]
  @identity_server_url @matrix_config[:identity_server_url]

  def client(conn, _params) do
    json(conn, %{
      "m.homeserver" => %{
        "base_url" => @homeserver_url
      },
      "m.identity_server" => %{
        "base_url" => @identity_server_url
      }
    })
  end

  def support(conn, _params) do
    json(conn, %{
      contacts: [
        %{
          email_address: @matrix_config[:admin_contact][:email],
          matrix_id: @matrix_config[:admin_contact][:matrix_id],
          role: "m.role.admin"
        }
      ]
    })
  end
end
