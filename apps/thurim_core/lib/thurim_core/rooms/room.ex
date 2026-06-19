defmodule ThurimCore.Rooms.Room do
  use Ecto.Schema
  alias ThurimCore.{EctoTypes.UnixTimestamp, Events.Event, Rooms.RoomAlias}

  @primary_key {:room_id, :string, autogenerate: false}
  schema "rooms" do
    field :room_version, :string
    field :creator, :string
    field :is_public, :boolean, default: false
    field :predecessor_room_id, :string
    field :successor_room_id, :string
    field :created_ts, UnixTimestamp, autogenerate: {DateTime, :utc_now, [:millisecond]}
    has_many :room_aliases, RoomAlias, foreign_key: :room_id, references: :room_id
    has_many :events, Event, foreign_key: :room_id, references: :room_id
  end
end
