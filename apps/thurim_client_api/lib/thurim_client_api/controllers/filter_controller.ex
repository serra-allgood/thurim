defmodule ThurimClientApi.FilterController do
  use ThurimClientApi, :controller
  alias ThurimCore.Filtering

  def create(conn, %{"user_id" => user_id} = params)
      when conn.assigns.current_user.user_id == user_id do
    case Filtering.create_filter(user_id, %{definition: params}) do
      {:ok, filter} ->
        json(conn, %{filter_id: filter.id})

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          errcode: "M_BAD_JSON",
          error: "Encoutered the following errors: #{changeset.errors}"
        })
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      errcode: "M_FORBIDDEN",
      error: "User ID in path parameter does not match access token user ID."
    })
  end

  def show(conn, %{"user_id" => user_id, "filter_id" => filter_id} = _params)
      when conn.assigns.current_user.user_id == user_id do
    case Filtering.get_filter(user_id, filter_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{errcode: "M_NOT_FOUND", error: "Filter not found."})

      filter ->
        json(conn, filter.definition)
    end
  end

  def show(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      errcode: "M_FORBIDDEN",
      error: "User ID in path parameter does not match access token user ID."
    })
  end
end
