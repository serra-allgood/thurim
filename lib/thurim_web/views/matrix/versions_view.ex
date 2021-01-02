defmodule ThurimWeb.Matrix.VersionsView do
  use ThurimWeb, :view

  def render("client.json", _assigns) do
    %{versions: ["r.0.6.1"]}
  end
end
