defmodule Thurim.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.Room
  alias Thurim.Events.EventStateKey
  alias Thurim.Events

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "events" do
    field :auth_event_ids, {:array, :binary_id}, default: []
    field :event_id, :string
    field :depth, :integer
    field :type, :string
    field :content, :map
    field :sender, :string
    field :origin_server_ts, :integer
    belongs_to :room, Room, references: :room_id, type: :string, foreign_key: :room_id

    belongs_to :event_state_key, EventStateKey,
      references: :state_key,
      type: :string,
      foreign_key: :state_key

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(
      attrs,
      [
        :depth,
        :auth_event_ids,
        :event_id,
        :type,
        :content,
        :state_key,
        :room_id,
        :sender,
        :origin_server_ts
      ],
      empty_values: []
    )
    |> set_defaults(
      origin_server_ts: Timex.now() |> DateTime.to_unix(:millisecond),
      event_id: Events.generate_event_id()
    )
    |> validate_required([
      :depth,
      :type,
      :content,
      :room_id,
      :event_id,
      :sender,
      :origin_server_ts
    ])
    |> assoc_constraint(:room)
    |> assoc_constraint(:event_state_key)
  end

  defp set_defaults(changeset, defaults) do
    Enum.reduce(defaults, changeset, fn {field, value}, changeset ->
      if get_field(changeset, field) |> is_nil() do
        put_change(changeset, field, value)
      else
        changeset
      end
    end)
  end

  # defp validate_not_nil(changeset, fields) do
  #   Enum.reduce(fields, changeset, fn field, changeset ->
  #     if get_field(changeset, field) |> is_nil() do
  #       add_error(changeset, field, "cannot be nil")
  #     else
  #       changeset
  #     end
  #   end)
  # end
end
