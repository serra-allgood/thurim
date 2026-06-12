defmodule ThurimCore.Keys.CrossSigningKey do
  use Ecto.Schema
  alias ThurimCore.Accounts.User

  @primary_key false
  schema "cross_signing_keys" do
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, primary_key: true
    field :key_type, :string, primary_key: true
    field :key_json, :map
  end
end
