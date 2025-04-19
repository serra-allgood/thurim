defmodule Thurim.DeviceMessages.DeviceMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "device_messages" do
    field :mx_user_id, :string
    field :device_id, :string
    field :type, :string
    field :content, :map
    field :sender, :string
    field :count, :integer
  end

  def changeset(device_message, attrs \\ %{}) do
    device_message
    |> cast(attrs, [:mx_user_id, :device_id, :type, :content, :sender])
    |> validate_required([:mx_user_id, :device_id, :type, :content, :sender])
  end
end
