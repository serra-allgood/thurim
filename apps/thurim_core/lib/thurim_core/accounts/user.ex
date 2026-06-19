defmodule ThurimCore.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.{Accounts.Device, Accounts.UserThreepid, EctoTypes.UnixTimestamp}

  @primary_key {:user_id, :string, autogenerate: false}
  schema "users" do
    field :localpart, :string
    field :password, Fields.Password, redact: true
    field :display_name, :string
    field :avatar_url, :string
    field :is_guest, :boolean, default: false
    field :is_admin, :boolean, default: false
    field :deactivated, :boolean, default: false
    field :appservice_id, :string
    field :created_ts, UnixTimestamp, autogenerate: {DateTime, :utc_now, [:millisecond]}
    has_many :devices, Device, foreign_key: :user_id, references: :user_id
    has_many :threepids, UserThreepid, foreign_key: :user_id, references: :user_id
  end

  def registration_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [
      :user_id,
      :localpart,
      :password,
      :is_guest,
      :created_ts,
      :appservice_id,
      :display_name,
      :avatar_url
    ])
    |> validate_required([:user_id, :localpart, :created_ts])
    |> validate_format(:user_id, ~r/^@[a-z0-9\._\-\/=\+]+:.+$/)
    |> unique_constraint(:localpart)
  end

  def update_password_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:user_id, :password])
    |> validate_required([:user_id, :password])
  end
end
