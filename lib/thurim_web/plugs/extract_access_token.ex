defmodule ThurimWeb.Plugs.ExtractAccessToken do
  alias Plug.Conn

  @access_token_query "access_token"
  @access_token_header "authoriation"

  def init(options), do: options

  def call(conn, _options) do
    #Fetch query params
    conn = Conn.fetch_query_params(conn)
    access_token_param = Map.get(conn.query_params, @access_token_query)

    #find "authorization" in request HTTP headers
    access_token_header = Conn.get_req_header(conn, @access_token_header) |> List.first

    case {access_token_param, access_token_header} do
      {nil, nil} -> conn
      {token, nil} ->
        #Token fetched from query params, assign value to connection
        Conn.assign(conn, :access_token, token)

      {nil, {_, token}} ->
        #authorization header found. Look for token in authorization value and assign it to connection
        case Regex.named_captures(~r/Bearer\ (?<token>.+)/, token) do
          %{"token" => token} -> Conn.assign(conn, :access_token, token)
          _ -> conn
        end
    end
  end
end
