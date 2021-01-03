defmodule Thurim.User.Device do
  use Ecto.Schema
  alias Thurim.User.Account
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "devices" do
    field :access_token, :string
    field :device_id, :string
    field :display_name, :string
    field :ip, :string
    field :last_seen_ts, :naive_datetime
    field :user_agent, :string
    belongs_to :account, Account, references: :localpart, type: :string

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:access_token, :device_id, :display_name, :last_seen_ts, :ip, :user_agent])
    |> validate_required([:access_token, :device_id, :display_name])
    |> unique_constraint(:access_token)
    |> unique_constraint([:account_id, :device_id])
  end
end
