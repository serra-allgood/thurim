defmodule ThurimCore.Events.EventEdge do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "event_edges" do
    field :event_id, :string, primary_key: true
    field :prev_event_id, :string, primary_key: true
  end

  def changeset(%__MODULE__{} = event_edge, attrs) do
    event_edge
    |> cast(attrs, [:event_id, :prev_event_id])
    |> validate_required([:event_id, :prev_event_id])
  end
end
