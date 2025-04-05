defmodule Thurim.DeviceKeys.DeviceKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Devices.Device

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "device_keys" do
    belongs_to :device, Device, references: :device_id, type: :string, foreign_key: :device_id
    field :algorithm, :string
    field :key, :string
    field :signatures, :map

    timestamps()
  end

  @doc false
  def changeset(device_key, attrs) do
    device_key
    |> cast(attrs, [:algorithm, :key, :signatures])
    |> validate_required([:algorithm, :key])
    |> assoc_constraint(:device)
  end
end
