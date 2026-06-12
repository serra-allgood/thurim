defmodule ThurimCore.Accounts.Device do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.EctoTypes.Inet

  @primary_key false
  schema "devices" do
    field :user_id, :string, primary_key: true
    field :device_id, :string, primary_key: true
    field :display_name, :string
    field :last_seen_ts, :utc_datetime_usec
    field :last_seen_ip, Inet
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:user_id, :device_id, :display_name, :last_seen_ts, :last_seen_ip])
    |> validate_required([:user_id, :device_id])
  end
end
