defmodule Thurim.Devices.Device do
  use Ecto.Schema
  alias Thurim.User.Account
  alias Thurim.AccessTokens.AccessToken
  import Ecto.Changeset

  @primary_key {:session_id, :binary_id, autogenerate: true}
  schema "devices" do
    field :device_id, :string
    field :display_name, :string
    field :ip, :string
    field :last_seen_ts, :naive_datetime
    field :user_agent, :string
    belongs_to :account, Account, references: :localpart, type: :string, foreign_key: :localpart
    has_one :access_token, AccessToken, foreign_key: :device_session_id

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:device_id, :display_name, :last_seen_ts, :ip, :user_agent, :localpart])
    |> validate_required([:device_id, :display_name])
    |> assoc_constraint(:account)
    |> unique_constraint([:localpart, :device_id])
  end
end
