defmodule Thurim.Events.EventStateKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "event_state_keys" do
    field :key, :string
  end

  @doc false
  def changeset(event_state_key, attrs) do
    event_state_key
    |> cast(attrs, [:key])
    |> validate_required([:key])
  end
end
