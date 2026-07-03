defmodule ThurimCore.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.EctoTypes.UnixTimestamp

  @primary_key {:event_id, :string, autogenerate: false}
  schema "events" do
    field :room_id, :string
    field :sender, :string
    field :type, :string
    # nil for message events
    field :state_key, :string
    field :content, :map
    field :depth, :integer
    field :origin_server_ts, UnixTimestamp
    field :stream_ordering, :integer
    field :hashes, :map
    field :signatures, :map
    field :unsigned, :map
    field :redacted_by, :string
    field :outlier, :boolean, default: false
    field :rejected_reason, :string
    field :prev_events, {:array, :string}, default: []
    field :auth_events, {:array, :string}, default: []
  end

  @required ~w(event_id room_id sender type content depth origin_server_ts prev_events auth_events)a
  @optional ~w(state_key hashes signatures unsigned outlier rejected_reason)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:type, min: 1)
    |> foreign_key_constraint(:room_id)
  end
end
