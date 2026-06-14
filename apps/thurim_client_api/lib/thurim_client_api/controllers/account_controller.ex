defmodule ThurimClientApi.AccountController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimit.AccountController when action in ~w(deactivate change_password)a

	def deactivate(conn, _params) do
		json_error(conn, :t_not_implemented)
	end

  def change_password(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def email(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def msisdn(conn, _params) do
    json_error(conn, :t_not_implemented)
  end
end
