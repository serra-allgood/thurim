defmodule Thurim.Events.EventJson do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Events.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "event_json" do
    field :event_json, :map
    belongs_to :event, Event, type: :integer
  end

  @doc false
  def changeset(event_json, attrs) do
    event_json
    |> cast(attrs, [:event_json])
    |> validate_required([:event_json])
    |> assoc_constraint(:event)
  end
end
