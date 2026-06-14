defmodule ThurimClientApi.SessionController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimit.SessionController
       when action in ~w(get_token login login_types refresh)a

  def get_token(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def login(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def login_types(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

	def logout(conn, _params) do
		json_error(conn, :t_not_implemented)
	end

	def logout_all(conn, _params) do
		json_error(conn, :t_not_implemented)
	end

	def refresh(conn, _params) do
		json_error(conn, :t_not_implemented)
	end
end
