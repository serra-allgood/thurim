defmodule Thurim.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.Room
  alias Thurim.Events.EventStateKey

  @primary_key {:id, :id, autogenerate: true}
  schema "events" do
    field :auth_event_ids, {:array, :integer}
    field :depth, :integer
    field :event_id, :string
    field :is_rejected, :boolean, default: false
    field :reference_sha256, :binary
    field :sent_to_output, :boolean, default: false
    field :type, :string
    field :content, :map
    belongs_to :room, Room, references: :room_id, type: :string
    belongs_to :event_state_keys, EventStateKey, references: :state_key, type: :string

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
      :type,
      :state_key,
      :content
    ])
    |> validate_required([
      :sent_to_output,
      :depth,
      :event_id,
      :reference_sha256,
      :auth_event_ids,
      :is_rejected,
      :type,
      :content,
      :state_key
    ])
    |> assoc_constraint(:room)
    |> assoc_constraint(:event_state_key)
  end
end
