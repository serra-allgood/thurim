defmodule Thurim.Rooms.RoomAlias do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.Room

  @primary_key false
  schema "room_aliases" do
    field :alias, :string, primary_key: true
    field :creator_id, :string
    belongs_to :room, Room, references: :room_id, type: :string

    timestamps()
  end

  @doc false
  def changeset(room_alias, attrs) do
    room_alias
    |> cast(attrs, [:alias, :room_id, :creator_id])
    |> validate_required([:alias, :room_id, :creator_id])
    |> assoc_constraint(:room)
  end
end
