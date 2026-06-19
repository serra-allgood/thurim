defmodule ThurimCore.Accounts.AccessToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.{Accounts.Device, Accounts.User, EctoTypes.UnixTimestamp}

  @max_token_age Application.compile_env(:thurim_core, [:matrix, :max_token_age])

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "access_tokens" do
    field :refresh_token, :string
    field :valid_until_ts, UnixTimestamp, autogenerate: {__MODULE__, :generate_valid_until_ts, []}
    field :created_ts, UnixTimestamp, autogenerate: {DateTime, :utc_now, [:millisecond]}
    belongs_to :user, User, foreign_key: :user_id, references: :user_id
    belongs_to :device, Device, foreign_key: :device_id, references: :device_id
  end

  def changeset(%__MODULE__{} = token, attrs) do
    token
    |> cast(attrs, [:user_id, :device_id, :refresh_token, :valid_until_ts, :created_ts])
    |> validate_required([:user_id, :device_id, :valid_until_ts, :created_ts])
  end

  def generate_valid_until_ts() do
    DateTime.utc_now(:millisecond)
    |> DateTime.shift(second: @max_token_age)
  end
end
