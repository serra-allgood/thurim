defmodule Thurim.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.RoomAlias
  alias Thurim.Events.Event

  @default_room_version Application.get_env(:thurim, :matrix)[:default_room_version]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :room_id, :string
    field :room_version, :string, default: @default_room_version
    field :published, :boolean, default: false
    has_many :room_aliases, RoomAlias, foreign_key: :room_id
    has_many :events, Event, foreign_key: :room_id

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:room_id, :room_version, :published])
    |> validate_required([:room_id, :room_version])
    |> unique_constraint(:room_id)
  end
end
