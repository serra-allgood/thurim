defmodule Thurim.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :last_event_sent_nid, :integer
    field :latest_event_nids, {:array, :integer}
    field :room_id, :string
    field :room_version, :string

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:room_id, :latest_event_nids, :last_event_sent_nid, :room_version])
    |> validate_required([:room_id, :room_version])
    |> unique_constraint(:room_id)
  end
end
