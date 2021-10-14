defmodule Thurim.Filters.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "filters" do
    field :id, :binary_id, primary_key: true, autogenerate: true
    field :filter, :map
    field :localpart, :string, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:filter, :localpart])
    |> validate_required([:filter, :localpart])
  end
end
