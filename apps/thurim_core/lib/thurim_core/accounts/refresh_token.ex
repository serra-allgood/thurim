defmodule ThurimCore.Accounts.RefreshToken do
  use Ecto.Schema

  @primary_key {:token, :string, autogenerate: false}
  schema "refresh_tokens" do
    field :user_id, :string
    field :device_id, :string
    field :expires_ts, :utc_datetime_usec
    field :created_ts, :utc_datetime_usec
    field :next_token, :string
  end
end
