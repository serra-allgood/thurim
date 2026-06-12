defmodule ThurimCore.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.Accounts.{Device, UserThreepid}

  @primary_key {:user_id, :string, autogenerate: false}
  schema "users" do
    field :localpart, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, Fields.Password, redact: true
    field :display_name, :string
    field :avatar_url, :string
    field :is_guest, :boolean, default: false
    field :is_admin, :boolean, default: false
    field :deactivated, :boolean, default: false
    field :appservice_id, :string
    field :created_ts, :utc_datetime_usec
    has_many :devices, Device, foreign_key: :user_id, references: :user_id
    has_many :threepids, UserThreepid, foreign_key: :user_id, references: :user_id
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :localpart, :password_hash, :is_guest, :created_ts])
    |> validate_required([:user_id, :localpart, :created_ts])
    |> validate_format(:user_id, ~r/^@[a-z0-9\._\-\/=\+]+:.+$/)
    |> unique_constraint(:localpart)
    |> unique_constraint(:user_id)
  end
end
