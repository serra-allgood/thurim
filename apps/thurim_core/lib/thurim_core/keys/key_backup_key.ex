defmodule ThurimCore.Keys.KeyBackupKey do
  use Ecto.Schema
  alias ThurimCore.Accounts.User

  @primary_key false
  schema "key_backup_keys" do
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, primary_key: true
    field :version, :string, primary_key: true
    field :room_id, :string, primary_key: true
    field :session_id, :string, primary_key: true
    field :key_data, :map
  end
end
