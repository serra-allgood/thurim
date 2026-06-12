defmodule ThurimCore.Keys.OneTimeKey do
  use Ecto.Schema

  @primary_key false
  schema "one_time_keys" do
    field :user_id, :string, primary_key: true
    field :device_id, :string, primary_key: true
    field :algorithm, :string, primary_key: true
    field :key_id, :string, primary_key: true
    field :key_json, :map
    field :is_fallback, :boolean, default: false
    field :claimed, :boolean, default: false
  end
end
