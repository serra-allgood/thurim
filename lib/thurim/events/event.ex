defmodule Thurim.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Thurim.Rooms.Room
  alias Thurim.Events.EventStateKey
  alias Thurim.Events

  @domain Application.compile_env(:thurim, [:matrix, :domain])

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "events" do
    field :auth_events, {:array, :string}
    field :event_id, :string
    field :depth, :integer
    field :type, :string
    field :content, :map
    field :sender, :string
    field :origin_server_ts, :integer
    field :origin, :string, default: @domain
    field :redacts, :string
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
        :auth_events,
        :event_id,
        :type,
        :content,
        :state_key,
        :room_id,
        :sender,
        :origin_server_ts,
        :origin,
        :redacts
      ],
      empty_values: []
    )
    |> set_defaults(origin_server_ts: generate_origin_server_ts())
    |> set_auth_events()
    |> set_event_id_hash()
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

  def generate_origin_server_ts do
    Timex.now() |> DateTime.to_unix(:millisecond)
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

  defp set_auth_events(changeset) do
    if get_field(changeset, :auth_events) == nil do
      case apply_action(changeset, :get_auth_events) do
        {:ok, event} ->
          auth_event_ids = Events.get_auth_event_ids(event)
          change(event, %{auth_events: auth_event_ids})

        {:error, changeset} ->
          add_error(changeset, :auth_events, "Could not get auth event ids")
      end
    else
      changeset
    end
  end

  defp set_event_id_hash(changeset) do
    if get_field(changeset, :event_id) |> is_nil() do
      case apply_action(changeset, :generate_event_id) do
        {:ok, event} ->
          event_id = Events.generate_event_id_hash(event)
          change(event, %{event_id: event_id})

        {:error, changeset} ->
          add_error(changeset, :event_id, "Could not generate event id hash")
      end
    else
      changeset
    end
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
