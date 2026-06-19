defmodule ThurimClientApi.CapabilityController do
  use ThurimClientApi, :controller

  plug ThurimClientApi.Plugs.RateLimiters.CapabilityController

  def index(conn, _params) do
    json(
      conn,
      %{
        "m.3pid_changes" => false,
        "m.change_password" => true,
        "m.forced_forget_upon_leave" => false,
        "m.get_login_token" => false,
        "m.profile_fields" => true,
        "m.room_version" => %{
          "available" => %{
            "12" => "stable"
          },
          "default" => "12"
        },
        "m.set_avatar_url" => true,
        "m.set_displayname" => true
      }
    )
  end
end
