defmodule Thurim.EventTypes.EventType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "event_types" do
    field :name, :string
  end

  @doc false
  def changeset(event_type, attrs) do
    event_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
