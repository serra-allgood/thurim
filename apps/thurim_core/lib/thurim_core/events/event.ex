defmodule ThurimCore.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:event_id, :string, autogenerate: false}
  schema "events" do
    field :room_id, :string
    field :sender, :string
    field :type, :string
    # nil for message events
    field :state_key, :string
    # jsonb
    field :content, :map
    field :depth, :integer
    field :origin_server_ts, :utc_datetime_usec
    # BIGSERIAL — assigned by DB, never set by app
    field :stream_ordering, :integer
    field :hashes, :map
    field :signatures, :map
    field :unsigned, :map
    field :redacted_by, :string
    field :outlier, :boolean, default: false
    field :rejected_reason, :string
  end

  @required ~w(event_id room_id sender type content depth origin_server_ts)a
  @optional ~w(state_key hashes signatures unsigned outlier rejected_reason)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:type, min: 1)
    |> unique_constraint(:event_id)
    |> foreign_key_constraint(:room_id)
  end

  def state_event?(%__MODULE__{state_key: state_key}), do: not is_nil(state_key)
end
