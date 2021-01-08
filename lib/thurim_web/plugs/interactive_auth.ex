defmodule ThurimWeb.Plugs.InteractiveAuth do
  alias Plug.Conn
  alias Thurim.Utils
  alias Thurim.User
  alias ThurimWeb.AuthSessionCache
  require Logger
  import Phoenix.Controller, only: [json: 2]

  @flows [
    %{stages: ["m.login.dummy"]},
    %{stages: ["m.login.password"]}
  ]

  def init(options), do: options

  def call(conn, _options) do
    auth = Map.get(conn.params, "auth")
    if valid_auth?(auth) do
      conn
      |> check_stage(auth)
      |> check_completed_stages()
      |> pass_or_challenge()
    else
      session_id = Utils.crypto_random_string()
      session = set_session(%{id: session_id, completed_stages: [], auth_completed: false})
      pass_or_challenge(conn, session)
    end
  end

  defp set_session(session) do
    AuthSessionCache.set(session.id, session)
  end

  defp get_session(session_id) do
    AuthSessionCache.get(session_id)
  end

  defp valid_auth?(auth) when is_nil(auth), do: false

  defp valid_auth?(auth) do
    get_session(auth["session"]) != nil
  end

  defp check_stage(conn, %{"type" => type} = auth) when type == "m.login.dummy" do
    session = get_session(auth["session"])
    add_completed_stage(type, session)
    conn
  end

  defp check_stage(conn, %{"type" => type} = auth) when type == "m.login.password" do
    session = get_session(auth["session"])
    %{"identifier" => %{"type" => "m.id.user", "user" => user}, "password" => password} = auth

    case User.authenticate(user, password) do
      {:ok, user} ->
        add_completed_stage(type, session)
        Conn.assign(conn, :current_user, user)

      {:error, :invalid_login} ->
        conn

      {:error, :not_found} ->
        if conn.path_info() == ["register"] do
          add_completed_stage(type, session)
        else
          conn
        end
    end
  end

  defp check_completed_stages(conn) do
    auth = Map.get(conn.params, "auth")
    session = get_session(auth["session"])

    check =
      Enum.map(@flows, fn flow -> flow.stages -- session.completed_stages end)
      |> Enum.find(fn stages -> length(stages) == 0 end)

    if check do
      set_session(%{session | auth_completed: true})
    end

    conn
  end

  defp pass_or_challenge(conn, session \\ nil)
  defp pass_or_challenge(conn, session) when not is_nil(session) do
    conn
    |> Conn.put_status(401)
    |> json(%{
      flows: @flows,
      session: session.id,
      params: [],
      completed: []
    })
    |> Conn.halt()
  end
  defp pass_or_challenge(conn, _session) do
    auth = Map.get(conn.params, "auth")
    session = get_session(auth["session"])

    if session.auth_completed do
      conn
    else
      conn
      |> Conn.put_status(401)
      |> json(%{
        flows: @flows,
        session: session.id,
        params: [],
        completed: []
      })
      |> Conn.halt()
    end
  end

  defp add_completed_stage(type, session) do
    set_session(%{
      session
      | completed_stages: [type | session.completed_stages]
    })
  end
end
