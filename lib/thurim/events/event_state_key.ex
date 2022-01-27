defmodule Thurim.Events.EventStateKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "event_state_keys" do
    field :state_key, :string
  end

  def changeset(event_state_key, attrs) do
    event_state_key
    |> cast(attrs, [:state_key])
    |> validate_required([:state_key])
    |> unique_constraint(:state_key)
  end
end
