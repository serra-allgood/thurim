defmodule Thurim.Repo do
  use Ecto.Repo,
    otp_app: :thurim,
    adapter: Ecto.Adapters.Postgres
end
