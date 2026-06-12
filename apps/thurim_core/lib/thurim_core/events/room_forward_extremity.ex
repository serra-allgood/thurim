defmodule ThurimCore.Events.RoomForwardExtremity do
  use Ecto.Schema

  @primary_key false
  schema "room_forward_extremities" do
    field :room_id, :string, primary_key: true
    field :event_id, :string, primary_key: true
  end
end
