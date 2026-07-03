defmodule ThurimCore.Filtering.Definition do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.Filtering.{EventFilter, RoomFilter}

  @formats ~w(client federation)

  @primary_key false
  embedded_schema do
    field :event_fields, {:array, :string}
    field :event_format, :string, default: "client"
    embeds_one :account_data, EventFilter, on_replace: :delete
    embeds_one :presence, EventFilter, on_replace: :delete
    embeds_one :room, RoomFilter, on_replace: :delete
  end

  def changeset(def, attrs) do
    def
    |> cast(attrs, [:event_fields, :event_format])
    |> validate_inclusion(:event_format, @formats)
    |> cast_embed(:account_data)
    |> cast_embed(:presence)
    |> cast_embed(:room)
  end
end
