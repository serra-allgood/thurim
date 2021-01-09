defmodule ThurimWeb.Controllers.MatrixController do
  defmacro __using__(_) do
    quote do
      import ThurimWeb.Errors
      # Get first error message from a changeset
      defp first_error_message(changeset) do
        {field, {error, _}} = changeset.errors |> List.first
        {error, field}
      end

      defp send_changeset_error_to_json(conn, errors) do
        case first_error_message(errors) do
          {"user_in_use", _} -> conn |> json_error(:m_user_in_use)
          {"empty_user_id_or_password", _} ->  conn |> json_error(:empty_user_id_or_password)
          {"invalid_user_id", _} -> conn |> json_error(:m_invalid_username)
          {"bad_type", field} -> conn |> json_error({:m_bad_type, field})
          {"unsupported_room_version", _} -> conn |> json_error(:m_unsupported_room_version)
          _ -> conn |> json_error(:bad_json)
        end
      end
    end
  end
end
