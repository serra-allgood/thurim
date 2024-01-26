defmodule Thurim.Globals.GlobalCount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "global_counts" do
    field :name, :string, primary_key: true
    field :count, :integer
  end

  def changeset(global, attrs) do
    global
    |> cast(attrs, [:name, :count])
    |> validate_required([:name, :count])
  end
end
