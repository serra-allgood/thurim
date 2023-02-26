defmodule Thurim.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.RoomAlias
  alias Thurim.Events.Event
  alias Thurim.Rooms

  @default_room_version Application.compile_env(:thurim, :matrix)[:default_room_version]
  @supported_room_versions Application.compile_env(:thurim, :matrix)[:supported_room_versions]

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
    |> set_defaults(room_id: Rooms.generate_room_id())
    |> validate_required([:room_id, :room_version])
    |> validate_inclusion(:room_version, @supported_room_versions)
    |> unique_constraint(:room_id)
  end

  defp set_defaults(changeset, defaults) do
    Enum.reduce(defaults, changeset, fn {field, value}, changeset ->
      if get_field(changeset, field) |> is_nil() do
        put_change(changeset, field, value)
      else
        changeset
      end
    end)
  end
end
