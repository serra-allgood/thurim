defmodule ThurimCore.Rooms.CurrentStateEvent do
  use Ecto.Schema
  alias ThurimCore.{Events.Event, Rooms.Room}

  @primary_key false
  schema "current_state_events" do
    belongs_to :room, Room, foreign_key: :room_id, references: :room_id, primary_key: true
    field :type, :string, primary_key: true
    field :state_key, :string, primary_key: true
    belongs_to :event, Event, foreign_key: :event_id, references: :event_id
  end
end
