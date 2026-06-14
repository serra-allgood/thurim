defmodule ThurimClientApi.RegistrationController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimit.RegistrationController
       when action in ~w(available register)a


  def available(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def email(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def msisdn(conn, _params) do
    json_error(conn, :t_not_implemented)
  end
  def register(conn, _params) do
    json_error(conn, :t_not_implemented)
  end
end
