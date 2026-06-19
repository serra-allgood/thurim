defmodule ThurimClientApi.VersionController do
  use ThurimClientApi, :controller

  def index(conn, _params) do
    json(conn, %{versions: ["v1.18"]})
  end
end
