defmodule Thurim.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Thurim.Repo

  alias Thurim.Events.Event
  alias Thurim.Events.EventStateKey
  alias Thurim.Events.EventData
  alias Thurim.Events.StrippedEventData

  @default_power_levels %{
    "ban" => 50,
    "events" => %{
      "m.room.avatar" => 50,
      "m.room.canonical_alias" => 50,
      "m.room.history_visibility" => 100,
      "m.room.name" => 50,
      "m.room.power_levels" => 100,
      "m.room.server_acl" => 100,
      "m.room.tombstone" => 100,
      "m.space.child" => 50,
      "m.room.topic" => 50,
      "m.room.pinned_events" => 50,
      "m.reaction" => 0,
      "im.vector.modular.widgets" => 50
    },
    "events_default" => 0,
    "historical" => 100,
    "invite" => 0,
    "kick" => 50,
    "redact" => 50,
    "state_default" => 50,
    "users_default" => 0
  }
  @domain Application.get_env(:thurim, :matrix)[:domain]

  def timeline_for_room_id(room_id) do
    from(e in Event,
      where: e.room_id == ^room_id,
      order_by: e.origin_server_ts
    )
    |> Repo.all()
  end

  def map_events(event) do
    cond do
      Enum.member?(StrippedEventData.stripped_events(), event.type) ->
        StrippedEventData.new(
          event.content,
          event.sender,
          event.state_key,
          event.type
        )

      true ->
        EventData.new(
          event.content,
          event.event_id,
          event.origin_server_ts,
          event.room_id,
          event.sender,
          event.type,
          event.state_key
        )
    end
  end

  def generate_event_id do
    "$" <> UUID.uuid4() <> ":" <> @domain
  end

  def get_by(attrs \\ []) do
    Repo.get_by(Event, attrs)
  end

  def user_previously_in_room?(sender, room_id) do
    latest_member_event = latest_state_event_of_type_in_room_id(room_id, "m.room.member", sender)

    latest_member_event != nil and
      Enum.member?(~w(leave kick ban), latest_member_event.content["membership"])
  end

  def latest_state_event_of_type_in_room_id(room_id, event_type, state_key, at_time \\ nil)

  def latest_state_event_of_type_in_room_id(room_id, event_type, state_key, at_time)
      when is_nil(at_time) do
    from(e in Event,
      where: e.room_id == ^room_id,
      where: e.type == ^event_type,
      where: e.state_key == ^state_key,
      order_by: [desc: e.origin_server_ts]
    )
    |> first()
    |> Repo.one()
  end

  def latest_state_event_of_type_in_room_id(room_id, event_type, state_key, at_time) do
    from(e in Event,
      where: e.room_id == ^room_id,
      where: e.type == ^event_type,
      where: e.state_key == ^state_key,
      where: e.origin_server_ts < ^at_time,
      order_by: [desc: e.origin_server_ts]
    )
    |> first()
    |> Repo.one()
  end

  def state_events_for_room_id(room_id) do
    from(e in Event,
      where: e.room_id == ^room_id and not is_nil(e.state_key),
      order_by: e.origin_server_ts
    )
    |> Repo.all()
  end

  def heroes_for_room_id(room_id, sender) do
    from(e in Event,
      where: e.room_id == ^room_id and e.type == "m.room.member" and e.state_key != ^sender,
      order_by: e.origin_server_ts,
      select: e.state_key
    )
    |> Repo.all()
  end

  def find_next_timestamp(timestamp) do
    from(e in Event,
      where: e.origin_server_ts >= ^timestamp,
      order_by: [desc: e.origin_server_ts],
      select: e.origin_server_ts,
      limit: 1
    )
    |> Repo.all()
    |> List.first()
  end

  def find_or_create_state_key(state_key) do
    event_state_key = get_event_state_key(state_key)

    if event_state_key do
      {:ok, event_state_key}
    else
      create_state_key(state_key)
    end
  end

  def get_event_state_key(state_key) do
    from(esk in EventStateKey, where: esk.state_key == ^state_key)
    |> Repo.one()
  end

  def create_state_key(state_key) do
    %EventStateKey{}
    |> EventStateKey.changeset(%{"state_key" => state_key})
    |> Repo.insert()
  end

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    Repo.all(Event)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs, "m.room.power_levels", depth) do
    {:ok, event_state_key} = find_or_create_state_key("")
    sender = Map.fetch!(attrs, "sender")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.power_levels",
      "state_key" => event_state_key.state_key,
      "content" =>
        Map.merge(
          Map.put(@default_power_levels, "users", %{sender => 100}),
          Map.get(attrs, "power_level_content_override", %{})
        )
    })
    |> create_event()
  end

  def create_event(attrs, "initial_state", depth) do
    event_state_key = Map.get(attrs, "event_state_key", nil)

    Map.merge(attrs, %{"state_key" => event_state_key, "depth" => depth})
    |> create_event()
  end

  def create_event(params, "m.room.create") do
    {:ok, event_state_key} = find_or_create_state_key("")

    Map.merge(params, %{
      "state_key" => event_state_key.state_key,
      "depth" => 1,
      "auth_event_ids" => [],
      "content" =>
        Map.get(params, "content_creation", %{})
        |> Map.merge(%{
          "creator" => Map.fetch!(params, "sender")
        }),
      "type" => "m.room.create",
      "room_id" => Map.fetch!(params, "room_id")
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.member", membership, depth) do
    {:ok, event_state_key} = Map.fetch!(attrs, "event_state_key") |> find_or_create_state_key()

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "state_key" => event_state_key.state_key,
      "type" => "m.room.member",
      "content" => %{
        "membership" => membership
      }
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.join_rules", join_rule, depth) do
    {:ok, event_state_key} = find_or_create_state_key("")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.join_rules",
      "state_key" => event_state_key.state_key,
      "content" =>
        Map.merge(
          %{
            "join_rule" => join_rule
          },
          Map.get(attrs, "content", %{})
        )
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.history_visibility", visibility, depth) do
    {:ok, event_state_key} = find_or_create_state_key("")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.history_visibility",
      "state_key" => event_state_key.state_key,
      "content" => %{
        "history_visibility" => visibility
      }
    })
    |> create_event()
  end

  def create_event(attrs, "m.room.guest_access", access, depth) do
    {:ok, event_state_key} = find_or_create_state_key("")

    attrs
    |> Map.merge(%{
      "depth" => depth,
      "type" => "m.room.guest_access",
      "state_key" => event_state_key.state_key,
      "content" => %{
        "guest_access" => access
      }
    })
    |> create_event()
  end

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end
end
