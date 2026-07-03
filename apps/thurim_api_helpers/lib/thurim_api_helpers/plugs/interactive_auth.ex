defmodule ThurimApiHelpers.Plugs.InteractiveAuth do
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn
  alias ThurimCore.{Accounts, MatrixConfig}
  alias ThurimApiHelpers.AuthSession

  def init(options), do: options

  def call(conn, _options) do
    auth = Map.get(conn.params, "auth")

    if valid_auth?(auth) do
      conn
      |> check_stage(auth)
      |> check_completed_stages()
      |> pass_or_challenge()
    else
      session = AuthSession.new()
      pass_or_challenge(conn, session)
    end
  end

	defp auth_flows do
		MatrixConfig.auth_flows()
	end

  defp valid_auth?(auth) when is_nil(auth), do: false

  defp valid_auth?(auth) do
    AuthSession.get_session(auth["session"]) != nil
  end

  defp check_stage(conn, %{"type" => type} = auth) when type == "m.login.dummy" do
    AuthSession.get_session(auth["session"])
    |> AuthSession.add_completed_stages(type)

    conn
  end

  defp check_stage(conn, %{"type" => type} = auth) when type == "m.login.password" do
    session = AuthSession.get_session(auth["session"])
    %{"identifier" => %{"type" => "m.id.user", "user" => user_id}, "password" => password} = auth

    case Accounts.authenticate_user(user_id, password) do
      {:ok, user} ->
        AuthSession.add_completed_stages(session, type)
        assign(conn, :user, user)

      {:error, :invalid_login} ->
        conn
    end
  end

  defp check_stage(conn, _auth), do: conn

  defp check_completed_stages(conn) do
    %{"auth" => auth} = conn.params

    case AuthSession.get_session(auth["session"]) do
      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: reason})
        |> halt()

      {:ok, nil} ->
        conn
        |> put_status(500)
        |> json(%{error: "We already check for nil auth session, so this should not be reached."})
        |> halt()

      {:ok, %AuthSession{} = session} ->
        check =
          Enum.map(auth_flows(), fn flow -> flow.stages -- session.completed_stages end)
          |> Enum.find(fn stages -> length(stages) == 0 end)

        if check || String.match?(conn.request_path, ~r{register}) do
          AuthSession.set_session(%AuthSession{session | auth_completed: true})
        end
    end

    conn
  end

  defp pass_or_challenge(conn, session \\ nil)

  defp pass_or_challenge(conn, session) when not is_nil(session) do
    conn
    |> put_status(401)
    |> json(%{
      flows: auth_flows(),
      session: session.id,
      params: [],
      completed: []
    })
    |> halt()
  end

  defp pass_or_challenge(%{params: %{"auth" => %{"session" => session_id}}} = conn, _session) do
    session = AuthSession.get_session(session_id)

    if session.auth_completed do
      conn
    else
      conn
      |> put_status(401)
      |> json(%{
        flows: auth_flows(),
        session: session.id,
        params: [],
        completed: session.completed_stages
      })
      |> halt()
    end
  end
end
