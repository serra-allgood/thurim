defmodule ThurimApiHelpers.Plugs.ExtractAccessToken do
  import Plug.Conn

  @access_token_query "access_token"
  @access_token_header "authorization"

  def init(options), do: options

  def call(conn, _options) do
    # Fetch query params
    conn = fetch_query_params(conn)
    access_token_from_param = Map.get(conn.query_params, @access_token_query)

    # find "authorization" in request HTTP headers
    access_token_from_header = get_req_header(conn, @access_token_header) |> List.first()

    case {access_token_from_param, access_token_from_header} do
      {nil, nil} ->
        conn

      # Token fetched from query params, assign value to connection
      {token, nil} ->
        assign(conn, :signed_access_token, token)

      # authorization header found. Look for token in authorization value and assign it to connection
      {nil, token} ->
        case Regex.named_captures(~r/Bearer\ (?<token>.+)/, token) do
          %{"token" => token} -> assign(conn, :signed_access_token, token)
          _ -> conn
        end
    end
  end
end
