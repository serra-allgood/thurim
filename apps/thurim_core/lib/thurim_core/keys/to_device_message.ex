defmodule ThurimCore.Keys.ToDeviceMessage do
  use Ecto.Schema

  @primary_key {:id, :integer, autogenerate: false}
  schema "to_device_messages" do
    field :target_user, :string
    field :target_device, :string
    field :sender, :string
    field :type, :string
    field :content, :map
  end
end
