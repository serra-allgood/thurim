defmodule ThurimClientApi.AccountController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimiters.AccountController
       when action in ~w(add_threepid bind_threepid deactivate change_password whoami)a

  def add_threepid(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def bind_threepid(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def delete_threepid(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

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

  def threepid(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def threepid_email(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def threepid_msisdn(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def unbind_threepid(conn, _params) do
    json_error(conn, :t_not_implemented)
  end

  def whoami(conn, _params) do
    json_error(conn, :t_not_implemented)
  end
end
