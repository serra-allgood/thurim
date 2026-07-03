defmodule ThurimCore.Filtering.RoomFilter do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.Filtering.RoomEventFilter

  @primary_key false
  embedded_schema do
    field :rooms, {:array, :string}
    field :not_rooms, {:array, :string}
    field :include_leave, :boolean, default: false
    embeds_one :account_data, RoomEventFilter, on_replace: :delete
    embeds_one :ephemeral, RoomEventFilter, on_replace: :delete
    embeds_one :state, RoomEventFilter, on_replace: :delete
    embeds_one :timeline, RoomEventFilter, on_replace: :delete
  end

  def changeset(room_filter, attrs) do
    room_filter
    |> cast(attrs, [:rooms, :not_rooms, :include_leave])
    |> cast_embed(:account_data)
    |> cast_embed(:ephemeral)
    |> cast_embed(:state)
    |> cast_embed(:timeline)
  end
end
