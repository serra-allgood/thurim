defmodule ThurimApiHelpers.ThurimRouter do
  defmacro __using__(_options) do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller

      pipeline :access_token do
        plug(ThurimApiHelpers.Plugs.ExtractAccessToken)
        plug(ThurimApiHelpers.Plugs.RequireAccessToken)
      end

      pipeline :interactive_auth do
        plug(ThurimApiHelpers.Plugs.InteractiveAuth)
      end
    end
  end
end
