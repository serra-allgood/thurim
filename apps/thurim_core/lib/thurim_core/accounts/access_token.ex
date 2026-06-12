defmodule ThurimCore.Accounts.AccessToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:token, :string, autogenerate: false}
  schema "access_tokens" do
    field :user_id, :string
    field :device_id, :string
    field :refresh_token, :string
    field :valid_until_ts, :integer
    field :created_ts, :integer
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :user_id, :device_id, :refresh_token, :valid_until_ts, :created_ts])
    |> validate_required([:token, :user_id, :created_ts])
  end
end
