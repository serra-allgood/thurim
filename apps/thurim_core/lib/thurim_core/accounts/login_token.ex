defmodule ThurimCore.Accounts.LoginToken do
  use Ecto.Schema

  @primary_key {:token, :string, autogenerate: false}
  schema "login_tokens" do
    field :user_id, :string
    field :expires_ts, :utc_datetime_usec
  end
end
