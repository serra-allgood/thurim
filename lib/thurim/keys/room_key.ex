defmodule Thurim.Keys.RoomKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Keys.KeyBackup

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "room_keys" do
    field :room_id, :string
    field :sessions, :map
    belongs_to :key_backup, KeyBackup
  end

  def changeset(room_key, attrs \\ %{}) do
    room_key
    |> cast(attrs, [:room_id, :sessions, :key_backup_id])
    |> validate_required([:room_id, :sessions, :key_backup_id])
    |> assoc_constraint(:key_backup)
  end
end
