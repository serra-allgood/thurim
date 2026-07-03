defmodule ThurimCore.Keys.ServerSigningKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.EctoTypes.UnixTimestamp

  @primary_key {:key_id, :string, autogenerate: false}
  schema "server_signing_keys" do
    field :algorithm, :string, default: "ed25519"
    field :version, :string
    field :public_key, :binary
    field :private_key, Fields.Encrypted
    field :public_b64, :string
    field :is_expired, :boolean, default: false
    field :valid_until_ts, UnixTimestamp, autogenerate: {__MODULE__, :generate_valid_until_ts, []}
    field :created_ts, UnixTimestamp, autogenerate: {DateTime, :utc_now, [:millisecond]}
  end

  @required [
    :key_id,
    :algorithm,
    :version,
    :public_key,
    :public_b64,
    :is_expired,
    :valid_until_ts,
    :created_ts
  ]
  @optional [:private_key]

  def create_changeset(%__MODULE__{} = key, attrs) do
    key
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end

  def generate_valid_until_ts do
    DateTime.utc_now(:millisecond)
    |> DateTime.shift(day: 1)
  end
end
