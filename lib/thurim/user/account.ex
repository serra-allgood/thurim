defmodule Thurim.User.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:localpart, :string, autogenerate: false}
  @foreign_key_type :string
  schema "accounts" do
    field :is_deactivated, :boolean, default: false
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:localpart, :password, :is_deactivated])
    |> validate_required([:localpart, :password, :is_deactivated])
    |> unique_constraint(:localpart)
    |> hash_password()
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp hash_password(changeset), do: changeset
end
