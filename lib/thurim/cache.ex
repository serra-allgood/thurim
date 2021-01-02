defmodule Thurim.Cache do
  use Nebulex.Cache,
    otp_app: :thurim,
    adapter: Nebulex.Adapters.Local
end
