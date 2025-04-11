defmodule Thurim.Keys.KeyBackup do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.User.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "key_backups" do
    field :version, :string
    field :algorithm, :string
    field :auth_data, :map
    field :etag
    belongs_to :account, Account, references: :localpart, type: :string, foreign_key: :localpart
  end

  def changeset(key_backup, attrs \\ %{}) do
    key_backup
    |> cast(attrs, [:version, :algorithm, :auth_data, :localpart, :etag])
    |> validate_required([:version, :algorithm, :auth_data, :etag])
    |> assoc_constraint(:localpart)
  end
end
