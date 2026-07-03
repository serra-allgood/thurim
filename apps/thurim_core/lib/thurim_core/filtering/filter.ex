defmodule ThurimCore.Filtering.Filter do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.Filtering.Definition

  @primary_key false
  schema "filters" do
    field :user_id, :string, primary_key: true
    field :filter_id, :string, primary_key: true, autogenerate: {UUID, :uuidv4, []}
    embeds_one :definition, Definition, on_replace: :delete
  end

  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:user_id, :filter_id])
    |> cast_embed(:definition, required: true)
    |> validate_required([:user_id, :filter_id])
  end
end
