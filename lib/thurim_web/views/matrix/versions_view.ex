defmodule ThurimWeb.Matrix.VersionsView do
  use ThurimWeb, :view

  def render("client.json", _assigns) do
    %{versions: ["1.2"]}
  end
end
