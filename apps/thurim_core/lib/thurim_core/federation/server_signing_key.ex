defmodule ThurimCore.Federation.ServerSigningKey do
  use Ecto.Schema
  alias ThurimCore.EctoTypes.UnixTimestamp

  @primary_key false
  schema "server_signing_keys" do
    field :server_name, :string, primary_key: true
    field :key_id, :string, primary_key: true
    field :verify_key, :string
    field :valid_until_is, UnixTimestamp
  end
end
