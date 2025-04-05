defmodule Thurim.Devices.Device do
  use Ecto.Schema
  alias Thurim.{AccessTokens.AccessToken}
  import Ecto.Changeset

  @primary_key {:session_id, :binary_id, autogenerate: true}
  schema "devices" do
    field :device_id, :string
    field :display_name, :string
    field :ip, :string
    field :last_seen_ts, :naive_datetime
    field :user_agent, :string
    field :is_deleted, :boolean
    field :version, :integer
    field :mx_user_id, :string
    field :localpart, :string
    has_one :access_token, AccessToken, foreign_key: :device_session_id

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [
      :device_id,
      :display_name,
      :last_seen_ts,
      :ip,
      :user_agent,
      :localpart,
      :is_deleted,
      :mx_user_id
    ])
    |> validate_required([:device_id, :localpart, :mx_user_id, :display_name])
    |> unique_constraint([:localpart, :mx_user_id, :device_id])
  end
end
