defmodule ThurimCore.Accounts.RefreshToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.EctoTypes.UnixTimestamp

  @primary_key {:token, :string, autogenerate: false}
  schema "refresh_tokens" do
    field :user_id, :string
    field :device_id, :string
    field :created_ts, UnixTimestamp, autogenerate: {DateTime, :utc_now, [:millisecond]}
    # field :next_token, :string
  end

  def changeset(%__MODULE__{} = token, attrs) do
    token
    |> cast(attrs, [:token, :user_id, :device_id, :created_ts])
    |> validate_required([:token, :user_id, :device_id, :created_ts])
  end
end
