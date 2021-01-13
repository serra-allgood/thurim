defmodule Thurim.Events.StateSnapshot do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.Room

  @primary_key {:id, :id, autogenerate: true}
  schema "state_snapshots" do
    field :state_block_ids, {:array, :integer}
    belongs_to :room, Room

    timestamps()
  end

  @doc false
  def changeset(state_snapshot, attrs) do
    state_snapshot
    |> cast(attrs, [:state_block_ids])
    |> validate_required([:state_block_ids])
    |> assoc_constraint(:room)
  end
end
