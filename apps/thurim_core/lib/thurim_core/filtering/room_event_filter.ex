defmodule ThurimCore.Filtering.RoomEventFilter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :limit, :integer
    field :senders, {:array, :string}
    field :not_senders, {:array, :string}
    field :types, {:array, :string}
    field :not_types, {:array, :string}
    field :rooms, {:array, :string}
    field :not_rooms, {:array, :string}
    field :contains_url, :boolean
    field :lazy_load_members, :boolean, default: false
    field :include_redundant_members, :boolean, default: false
    field :unread_thread_notifications, :boolean, default: false
  end

  @fields ~w(limit senders not_senders types not_types rooms not_rooms
             contains_url lazy_load_members include_redundant_members
             unread_thread_notifications)a

  def changeset(room_event_filter, attrs) do
    room_event_filter
    |> cast(attrs, @fields)
    |> validate_number(:limit, greater_than_or_equal_to: 0)
    |> validate_redundant_members_requires_lazy_load()
  end

  defp validate_redundant_members_requires_lazy_load(changeset) do
    if get_field(changeset, :include_redundant_members) &&
         !get_field(changeset, :lazy_load_members) do
      add_error(changeset, :include_redundant_members, "requires lazy_load_members to be true")
    else
      changeset
    end
  end
end
