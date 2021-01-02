defmodule ThurimWeb.Plugs.InteractiveAuth do
  alias Plug.Conn
  alias Thurim.Utils
  import Phoenix.Controller, only: [json: 2]

  @flows [
    %{stages: ["m.login.dummy"]},
    %{stages: ["m.login.password"]}
  ]

  def init(options), do: options

  def call(conn, _options) do
    if false do
      conn
    else
      session_id = Utils.crypto_random_string()
      conn
        |> Conn.put_session(:interactive_auth, %{id: session_id})
        |> json(%{
          flows: @flows,
          session: session_id,
          params: [],
          completed: []
        })
        |> Conn.halt()
    end
  end
end
