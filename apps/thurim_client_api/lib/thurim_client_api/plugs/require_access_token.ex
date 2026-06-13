defmodule ThurimClientApi.Plugs.RequireAccessToken do
  import ThurimClientApi.Errors
  alias ThurimCore.Accounts
  alias Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, signed_access_token} <- Map.fetch(conn.assigns, :signed_access_token),
         {:ok, access_token} when not is_nil(access_token) <-
           Accounts.verify_signed_access_token(signed_access_token) do
      conn
      |> Conn.assign(:device_id, access_token.device)
      |> Conn.assign(:access_token, access_token)
      |> Conn.assign(:user, access_token.user)
    else
      :error ->
        conn |> json_error(:m_missing_token) |> Conn.halt()

      {:error, :unknown_token} ->
        conn |> json_error(:m_unknown_token) |> Conn.halt()
    end
  end
end
