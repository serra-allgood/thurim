# defmodule ThurimCore.Accounts.LoginToken do
#   use Ecto.Schema
# 	alias ThurimCore.EctoTypes.UnixTimestamp

#   @primary_key {:token, :string, autogenerate: false}
#   schema "login_tokens" do
#     field :user_id, :string
#     field :expires_ts, UnixTimestamp
#   end
# end
