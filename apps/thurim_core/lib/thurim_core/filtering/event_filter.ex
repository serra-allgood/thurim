defmodule ThurimCore.Filtering.EventFilter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :limit, :integer
    field :senders, {:array, :string}
    field :not_senders, {:array, :string}
    field :types, {:array, :string}
    field :not_types, {:array, :string}
  end

  def changeset(event_filter, attrs) do
    event_filter
    |> cast(attrs, [:limit, :senders, :not_senders, :types, :not_types])
    |> validate_number(:limit, greater_than_or_equal_to: 0)
  end
end
