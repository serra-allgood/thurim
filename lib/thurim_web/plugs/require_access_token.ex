defmodule ThurimWeb.Plugs.RequireAccessToken do
  alias Thurim.AccessTokens
  alias Plug.Conn
  import ThurimWeb.Errors

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- Map.fetch(conn.assigns, :signed_access_token),
         {:ok, access_token} when not is_nil(access_token) <- AccessTokens.verify(token) do
      conn
      |> Conn.assign(:current_account, access_token.account)
      |> Conn.assign(:current_device, access_token.device)
      |> Conn.assign(:access_token, access_token)
      |> Conn.assign(:sender, Thurim.User.mx_user_id(access_token.account.localpart))
    else
      :error ->
        conn |> json_error(:m_missing_token) |> Conn.halt()

      {:error, :unknown_token} ->
        conn |> json_error(:m_unknown_token) |> Conn.halt()
    end
  end
end
