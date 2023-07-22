defmodule Thurim.SyncTokens.SyncToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.{Devices.Device, Snapshots.Snapshot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sync_tokens" do
    belongs_to :device, Device,
      references: :session_id,
      type: :binary_id,
      foreign_key: :device_session_id

    has_many :snapshots, Snapshot

    timestamps()
  end

  @doc false
  def changeset(sync_token, attrs) do
    sync_token
    |> cast(attrs, [])
    |> validate_required([])
    |> assoc_constraint(:device)
  end
end
