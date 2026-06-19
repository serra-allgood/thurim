defmodule ThurimCore.Federation.Destination do
  use Ecto.Schema
  alias ThurimCore.EctoTypes.UnixTimestamp

  @primary_key {:destination, :string, autogenerate: false}
  schema "federation_destinations" do
    field :last_successful_ts, UnixTimestamp
    field :retry_interval, :integer, default: 0
    field :retry_last_ts, UnixTimestamp
  end
end
