defmodule ThurimWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ThurimWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ThurimWeb.ConnCase

      alias ThurimWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint ThurimWeb.Endpoint

      def get_auth_session(conn) do
        %{"session" => session} =
          conn
          |> add_basic_headers()
          |> post(Routes.user_path(conn, :create))
          |> json_response(401)

        session
      end

      def add_basic_headers(conn) do
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("user-agent", "TEST")
      end

      def create_user(conn, username, password) do
        request = %{
          "auth" => %{
            "session" => get_auth_session(conn),
            "type" => "m.login.dummy"
          },
          "username" => username,
          "password" => password
        }

        conn
        |> add_basic_headers()
        |> post(Routes.user_path(conn, :create), request)
        |> json_response(200)
      end
    end
  end

  setup tags do
    Thurim.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
