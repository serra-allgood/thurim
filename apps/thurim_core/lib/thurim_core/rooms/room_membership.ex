defmodule ThurimCore.Rooms.RoomMembership do
  use Ecto.Schema
  alias ThurimCore.{Events.Event, Rooms.Room}

  schema "room_memberships" do
    belongs_to :room, Room, foreign_key: :room_id, references: :room_id, primary_key: true
    field :user_id, :string, primary_key: true
    field :membership, :string
    belongs_to :event, Event, foreign_key: :event_id, references: :event_id
  end
end
