defmodule Thurim.DeviceKeys.OneTimeKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Devices.Device

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "one_time_keys" do
    belongs_to :device, Device, references: :device_id, type: :string, foreign_key: :device_id
    field :algorithm, :string
    field :key_id, :string
    field :key, :string
    field :signatures, :map
  end

  def changeset(one_time_key, attrs) do
    one_time_key
    |> cast(attrs, [:device_id, :algorithm, :key_id, :key, :signatures])
    |> validate_required([:algorithm, :key_id, :key, :signatures])
    |> assoc_constraint(:device)
  end
end
