defmodule ThurimCore.Repo do
  use Ecto.Repo,
    otp_app: :thurim_core,
    adapter: Ecto.Adapters.Postgres
end
