defmodule ThurimGateway.WellKnownController do
  use ThurimGateway, :controller
  alias ThurimCore.MatrixConfig

  def client(conn, _params) do
    json(conn, %{
      "m.homeserver" => %{
        "base_url" => MatrixConfig.homeserver_url()
      },
      "m.identity_server" => %{
        "base_url" => MatrixConfig.identity_server_url()
      }
    })
  end

  def support(conn, _params) do
    json(conn, %{
      contacts: [
        %{
          email_address: MatrixConfig.admin_email(),
          matrix_id: MatrixConfig.admin_mx_id(),
          role: "m.role.admin"
        }
      ]
    })
  end
end
