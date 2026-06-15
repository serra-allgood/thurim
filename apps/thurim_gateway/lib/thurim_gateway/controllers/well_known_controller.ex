defmodule ThurimGateway.WellKnownController do
  use ThurimGateway, :controller

  def client(conn, _params) do
    json_error(conn, :t_no_implemented)
  end

  def server(conn, _params) do
    json_error(conn, :t_no_implemented)
  end

  def support(conn, _params) do
    json_error(conn, :t_no_implemented)
  end
end
