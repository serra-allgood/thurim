defmodule ThurimCore.Cache.AuthSessionCache do
  use Nebulex.Cache,
    otp_app: :thurim_core,
    adapter: Nebulex.Adapters.Cachex
end
