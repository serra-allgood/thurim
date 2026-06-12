defmodule MatrixCore.Events.EventEdge do
  use Ecto.Schema
  @primary_key false
  schema "event_edges" do
    field :event_id, :string, primary_key: true
    field :prev_event_id, :string, primary_key: true
  end
end
