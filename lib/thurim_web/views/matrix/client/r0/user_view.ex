defmodule ThurimWeb.Matrix.Client.R0.UserView do
  use ThurimWeb, :view

  def render("index.json", _assigns) do
    %{flows: [%{type: "m.login.password"}]}
  end
end
