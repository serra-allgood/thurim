defmodule ThurimCore.Keys.KeyBackupVersion do
  use Ecto.Schema
  alias ThurimCore.Accounts.User

  @primary_key false
  schema "key_backup_versions" do
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, primary_key: true
    field :version, :string, primary_key: true
    field :algorithm, :string
    field :auth_data, :map
    field :etag, :integer
    field :deleted, :boolean, default: false
  end
end
