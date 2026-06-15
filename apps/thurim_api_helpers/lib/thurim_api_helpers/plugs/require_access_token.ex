defmodule ThurimApiHelpers.Plugs.RequireAccessToken do
  import Plug.Conn
  import ThurimApiHelpers.Errors
  alias ThurimCore.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, signed_access_token} <- Map.fetch(conn.assigns, :signed_access_token),
         {:ok, access_token} when not is_nil(access_token) <-
           Accounts.verify_signed_access_token(signed_access_token) do
      conn
      |> assign(:device_id, access_token.device)
      |> assign(:access_token, access_token)
      |> assign(:user, access_token.user)
    else
      :error ->
        conn |> json_error(:m_missing_token) |> halt()

      {:error, :unknown_token} ->
        conn |> json_error(:m_unknown_token) |> halt()
    end
  end
end
