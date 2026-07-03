defmodule ThurimCore.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.{EctoTypes.UnixTimestamp, Events.Event, MatrixConfig, Rooms.RoomAlias}

  @primary_key {:room_id, :string, autogenerate: false}
  schema "rooms" do
    field :room_version, :string
    field :creator, :string
    field :is_public, :boolean, default: false
    field :predecessor_room_id, :string
    field :successor_room_id, :string
    field :created_ts, UnixTimestamp, autogenerate: {DateTime, :utc_now, [:millisecond]}
    # has_many :room_aliases, RoomAlias, foreign_key: :room_id, references: :room_id
    has_many :events, Event, foreign_key: :room_id, references: :room_id
  end

  @create_fields ~w(room_id room_version creator is_public predecessor_room_id created_ts)a

  def create_changeset(%__MODULE__{} = room, attrs) do
    room
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_inclusion(:room_version, MatrixConfig.supported_room_versions())
  end
end
