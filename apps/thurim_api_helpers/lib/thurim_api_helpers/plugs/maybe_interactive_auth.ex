defmodule ThurimApiHelpers.Plugs.MaybeInteractiveAuth do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _options) do
    # TODO
  end
end
