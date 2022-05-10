defmodule ThurimWeb.Matrix.Client.R0.FilterController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.Filters

  def create(conn, params) do
    account = Map.get(conn.assigns, "current_account")

    filter_content =
      Map.take(params, ["event_fields", "event_format", "presence", "account_data", "room"])

    filter = %{"localpart" => account.localpart, "filter" => filter_content}

    case Filters.create_filter(filter) do
      {:ok, filter} -> json(conn, %{filter_id: filter.id})
      {:error, changeset} -> send_changeset_error_to_json(conn, changeset)
    end
  end
end
