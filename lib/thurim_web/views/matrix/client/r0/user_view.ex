defmodule ThurimWeb.Matrix.Client.R0.UserView do
  use ThurimWeb, :view
  alias Thurim.User

  def render("index.json", %{flows: flows}) do
    %{flows: flows}
  end

  def render("create.json", %{inhibit_login: true, account: account}) do
    %{user_id: User.mx_user_id(account.localpart)}
  end

  def render("create.json", %{
        inhibit_login: false,
        account: account,
        device: device,
        signed_access_token: signed_access_token
      }) do
    %{
      user_id: User.mx_user_id(account.localpart),
      access_token: signed_access_token,
      device_id: device.device_id
    }
  end
end
