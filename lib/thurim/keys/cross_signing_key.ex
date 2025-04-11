defmodule Thurim.Keys.CrossSigningKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cross_signing_keys" do
    field :mx_user_id, :string
    field :usage, {:array, :string}
    field :keys, :map
    field :signatures, :map

    timestamps()
  end

  @doc false
  def changeset(cross_signing_key, attrs) do
    cross_signing_key
    |> cast(attrs, [:mx_user_id, :usage, :keys, :signatures])
    |> validate_required([:mx_user_id, :usage, :keys, :signatures])
  end
end
