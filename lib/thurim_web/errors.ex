defmodule ThurimWeb.Errors do
  # Inspired by https://github.com/bismark/matrex/blob/master/lib/matrex_web/errors.ex
  import Phoenix.Controller, only: [json: 2]
  alias Plug.Conn

  @typep error :: atom | {atom, any}

  @spec json_error(Conn.t(), error) :: Conn.t()
  def json_error(conn, error) do
    conn
    |> Conn.put_status(status_code(error))
    |> json(%{
      errcode: error(error),
      error: message(error)
    })
  end

  @spec error(error) :: String.t()
  defp error(:m_forbidden), do: "M_FORBIDDEN"
  defp error(:m_unknown_token), do: "M_UNKNOWN_TOKEN"
  defp error(:m_missing_token), do: "M_MISSING_TOKEN"
  defp error({:m_missing_arg, _}), do: "M_BAD_JSON"
  defp error({:m_bad_type, _}), do: "M_BAD_JSON"
  defp error({:m_not_json, _}), do: "M_NOT_JSON"
  defp error(:m_not_found), do: "M_NOT_FOUND"
  defp error(:m_limit_exceeded), do: "M_LIMIT_EXCEEDED"
  defp error(:m_unknown), do: "M_UNKNOWN"
  defp error(:m_unauthorized), do: "M_UNAUTHORIZED"
  defp error(:m_user_deactivated), do: "M_USER_DEACTIVATED"
  defp error(:m_user_in_use), do: "M_USER_IN_USE"
  defp error(:m_invalid_username), do: "M_INVALID_USERNAME"
  defp error(:m_room_in_use), do: "M_ROOM_IN_USE"
  defp error(:m_invalid_room_state), do: "M_INVALID_ROOM_STATE"
  defp error(:m_threepid_in_use), do: "M_THREEPID_IN_USE"
  defp error(:m_threepid_not_found), do: "M_THREEPID_NOT_FOUND"
  defp error(:m_threepid_auth_failed), do: "M_THREEPID_AUTH_FAILED"
  defp error(:m_threepid_denied), do: "M_THREEPID_DENIED"
  defp error(:m_server_not_trusted), do: "M_SERVER_NOT_TRUSTED"
  defp error(:m_unsupported_room_version), do: "M_UNSUPPORTED_ROOM_VERSION"
  defp error(:m_incompatible_room_version), do: "M_INCOMPATIBLE_ROOM_VERSION"
  defp error(:m_bad_state), do: "M_BAD_STATE"
  defp error(:m_guest_access_forbidden), do: "M_GUEST_ACCESS_FORBIDDEN"
  defp error(:m_captcha_needed), do: "M_CAPTCHA_NEEDED"
  defp error(:m_captcha_invalid), do: "M_CAPTCHA_INVALID"
  defp error(:m_missing_param), do: "M_MISSING_PARAM"
  defp error(:m_invalid_param), do: "M_INVALID_PARAM"
  defp error(:m_too_large), do: "M_TOO_LARGE"
  defp error(:m_exclusive), do: "M_EXCLUSIVE"
  defp error(:m_resource_limit_exceeded), do: "M_RESOURCE_LIMIT_EXCEEDED"
  defp error(:m_cannot_leave_server_notice_room), do: "M_CANNOT_LEAVE_SERVER_NOTICE_ROOM"
  defp error(:p_internal_error), do: "P_INTERNAL_ERROR"
  defp error(:p_not_implemented), do: "P_NOT_IMPLEMENTED"
  defp error(_), do: "M_UNRECOGNIZED"

  @spec status_code(error) :: integer
  defp status_code(:m_user_in_use), do: 400
  defp status_code(:m_invalid_username), do: 400
  defp status_code(:m_invalid_room_state), do: 400
  defp status_code({:m_missing_arg, _}), do: 400
  defp status_code({:m_bad_type, _}), do: 400
  defp status_code(:m_unknown), do: 400
  defp status_code(:m_forbidden), do: 403
  defp status_code(:m_missing_token), do: 401
  defp status_code(:m_unknown_token), do: 401
  defp status_code(:m_not_found), do: 404
  defp status_code(:p_internal_error), do: 403
  defp status_code(:p_not_implemented), do: 500
  defp status_code(:m_unsupported_room_version), do: 400
  defp status_code(_), do: 500

  @spec message(error) :: String.t()
  defp message(:m_user_in_use), do: "User ID already taken"
  defp message(:m_invalid_username), do: "User ID is invalid"
  defp message({:m_missing_arg, key}), do: "Missing required key #{key}"
  defp message({:m_bad_type, key}), do: "Bad type for key #{key}"
  defp message(:m_unknown), do: "Bad login type"
  defp message(:m_forbidden), do: "Forbidden"
  defp message(:m_missing_token), do: "Access token missing"
  defp message(:m_unknown_token), do: "Unknown access token"
  defp message(:m_not_found), do: "Not found"
  defp message(:p_internal_error), do: "Thurim internal error"
  defp message(:p_not_implemented), do: "API endpoint not yet implemented"
  defp message(_), do: "Unknown Error"
end
