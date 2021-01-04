defmodule ThurimWeb.AuthSessionCache do
  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local
end
