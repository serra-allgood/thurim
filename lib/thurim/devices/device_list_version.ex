defmodule Thurim.Devices.DeviceListVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:user_id, :string, autogenerate: false}
  schema "device_list_versions" do
    field :version, :integer
  end

  def changeset(device_list_version, attrs) do
    device_list_version
    |> cast(attrs, [:user_id, :version])
    |> validate_required([:user_id, :version])
  end
end
