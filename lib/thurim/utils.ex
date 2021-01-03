defmodule Thurim.Utils do
  def crypto_random_string(length \\ 30) do
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end

  def get_ua_repr(conn) do
    ua = get_ua(conn)
    "#{ua} on #{ua.os}/#{ua.device}"
  end

  def get_ua(conn) do
    conn
    |> Plug.Conn.get_req_header("user-agent")
    |> List.first()
    |> UAParser.parse()
  end
end
