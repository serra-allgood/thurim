defmodule ThurimCore.Federation.Outbound do
  use Ecto.Schema

  @primary_key false
  schema "federation_outbound" do
    field :destination, :string, primary_key: true
    field :stream_id, :integer, primary_key: true
    field :pdu_event_id, :string
    field :edu_json, :map
  end
end
