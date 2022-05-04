defmodule Thurim.Events.EventStateKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Events.Event

  @primary_key {:id, :id, autogenerate: true}
  schema "event_state_keys" do
    field :state_key, :string
    has_many :events, Event, foreign_key: :state_key
  end

  def changeset(event_state_key, attrs) do
    event_state_key
    |> cast(attrs, [:state_key], empty_values: [])
    |> validate_not_nil([:state_key])
    |> unique_constraint(:state_key)
  end

  def validate_not_nil(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, changeset ->
      if get_field(changeset, field) |> is_nil() do
        add_error(changeset, field, "cannot be nil")
      else
        changeset
      end
    end)
  end
end
