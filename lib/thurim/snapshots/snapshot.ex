defmodule Thurim.Snapshots.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.{Events.Event, SyncTokens.SyncToken}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "snapshots" do
    belongs_to :sync_token, SyncToken
    belongs_to :event, Event, references: :event_id, type: :string

    timestamps()
  end

  @doc false
  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [])
    |> validate_required([])
    |> assoc_constraint(:sync_token)
    |> assoc_constraint(:event)
  end
end
