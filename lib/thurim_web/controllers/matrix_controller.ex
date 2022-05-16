defmodule ThurimWeb.Controllers.MatrixController do
  alias Thurim.Filters.Filter
  alias Thurim.Filters

  defmacro __using__(_) do
    quote do
      import ThurimWeb.Errors
      # Get first error message from a changeset
      defp first_error_message(changeset) do
        {field, {error, _}} = changeset.errors |> List.first()
        {error, field}
      end

      defp send_changeset_error_to_json(conn, errors) do
        case first_error_message(errors) do
          {"user_in_use", _} -> conn |> json_error(:m_user_in_use)
          {"empty_user_id_or_password", _} -> conn |> json_error(:empty_user_id_or_password)
          {"invalid_user_id", _} -> conn |> json_error(:m_invalid_username)
          {"bad_type", field} -> conn |> json_error({:m_bad_type, field})
          {"unsupported_room_version", _} -> conn |> json_error(:m_unsupported_room_version)
          _ -> conn |> json_error(:bad_json)
        end
      end

      defp get_filter(filter, account) do
        cond do
          filter == nil ->
            nil

          String.starts_with?(filter, "{") ->
            case Jason.decode(filter) do
              {:ok, filter_content} -> %Filter{filter: filter_content}
              {:error, _} -> nil
            end

          true ->
            case Filters.get_by(id: filter, localpart: account.localpart) do
              nil -> nil
              filter -> filter
            end
        end
      end
    end
  end
end
