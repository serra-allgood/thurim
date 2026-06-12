defmodule ThurimCore.Federation.Destination do
  use Ecto.Schema

  @primary_key {:destination, :string, autogenerate: false}
  schema "federation_destinations" do
    field :last_successful_ts, :utc_datetime_usec
    field :retry_interval, :integer, default: 0
    field :retry_last_ts, :utc_datetime_usec
  end
end
