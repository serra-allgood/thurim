defmodule Thurim.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :avatar_url, :string
    field :display_name, :string
    field :localpart, :string, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:localpart, :display_name, :avatar_url])
    |> validate_required([:localpart])
  end
end
