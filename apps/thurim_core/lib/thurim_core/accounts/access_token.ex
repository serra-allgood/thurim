defmodule ThurimCore.Accounts.AccessToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.{Accounts.Device, Accounts.User}

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "access_tokens" do
    field :refresh_token, :string
    field :valid_until_ts, :integer
    field :created_ts, :integer, autogenerate: {DateTime, :utc_now, [:microsecond]}
    belongs_to :user, User, foreign_key: :user_id, references: :user_id
    belongs_to :device, Device, foreign_key: :device_id, references: :device_id
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:user_id, :device_id, :refresh_token, :valid_until_ts, :created_ts])
    |> validate_required([:user_id, :device_id, :valid_until_ts, :created_ts])
  end
end
