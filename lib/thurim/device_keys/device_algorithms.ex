defmodule Thurim.DeviceKeys.DeviceAlgorithms do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:device_id, :string, autogenerate: false}
  schema "device_algorithms" do
    field :supported_algorithms, {:array, :string}
  end

  def changeset(device_algorithm, attrs) do
    device_algorithm
    |> cast(attrs, [:device_id, :supported_algorithms])
    |> validate_required([:device_id, :supported_algorithms])
  end
end
