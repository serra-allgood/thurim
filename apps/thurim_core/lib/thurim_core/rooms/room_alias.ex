# defmodule ThurimCore.Rooms.RoomAlias do
#   use Ecto.Schema
#   alias ThurimCore.Rooms.Room

#   @primary_key {:alias, :string, autogenerate: false}
#   schema "room_aliases" do
#     field :creator, :string
#     field :is_canonical, :boolean, default: false
#     field :servers, {:array, :string}
#     belongs_to :room, Room, references: :room_id
#   end
# end
