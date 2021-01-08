defmodule Thurim.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:localpart, :string, autogenerate: false}
  schema "profiles" do
    field :avatar_url, :string
    field :display_name, :string

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:localpart, :display_name, :avatar_url])
    |> validate_required([:localpart])
    |> unique_constraint(:localpart, name: :profiles_pkey)
  end
end
