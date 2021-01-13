defmodule Thurim.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.Room

  @primary_key {:id, :id, autogenerate: true}
  schema "events" do
    field :auth_event_ids, {:array, :integer}
    field :depth, :integer
    field :event_id, :string
    field :is_rejected, :boolean, default: false
    field :reference_sha256, :binary
    field :sent_to_output, :boolean, default: false
    field :event_type_id, :integer
    field :event_state_key_id, :integer
    field :state_snapshot_id, :integer, default: 0
    belongs_to :room, Room

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :sent_to_output,
      :depth,
      :event_id,
      :reference_sha256,
      :auth_event_ids,
      :is_rejected,
      :event_type_id,
      :event_state_key_id,
      :state_snapshot_id
    ])
    |> validate_required([
      :sent_to_output,
      :depth,
      :event_id,
      :reference_sha256,
      :auth_event_ids,
      :is_rejected,
      :event_type_id,
      :event_state_key_id,
      :state_snapshot_id
    ])
    |> assoc_constraint(:room)
  end
end
