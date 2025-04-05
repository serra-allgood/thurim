defmodule Thurim.User.Account do
  use Ecto.Schema
  alias Thurim.Devices.Device
  alias Thurim.AccessTokens.AccessToken
  import Ecto.Changeset

  @localpart_regex ~r|^[a-z0-9\-\.\=\_\/]+$|
  @domain Application.compile_env(:thurim, [:matrix, :domain])

  @primary_key {:localpart, :string, autogenerate: false}
  @foreign_key_type :string
  schema "accounts" do
    field :is_deactivated, :boolean, default: false
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    timestamps()

    has_many :devices, Device, foreign_key: :localpart, where: [server_name: @domain]
    has_many :access_tokens, AccessToken, foreign_key: :localpart
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:localpart, :password, :is_deactivated])
    |> validate_required([:localpart, :is_deactivated])
    |> validate_format(:localpart, @localpart_regex, message: "invalid_user_id")
    |> validate_length(:localpart, max: 255)
    |> unique_constraint(:localpart, name: :accounts_pkey, message: "user_in_use")
    |> hash_password()
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp hash_password(changeset), do: changeset
end
