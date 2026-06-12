defmodule ThurimCore.Keys.DeviceKey do
  use Ecto.Schema

  @primary_key false
  schema "device_keys" do
    field :user_id, :string, primary_key: true
    field :device_id, :string, primary_key: true
    field :key_json, :map
    field :stream_id, :integer
  end
end
