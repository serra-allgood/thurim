defmodule Thurim.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Thurim.Repo

  alias Thurim.Events.Event
  alias Thurim.Events.EventStateKey
  alias Thurim.Events.EventData
  alias Thurim.Events.StrippedEventData
  alias Thurim.Transactions

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

  def map_client_event(event) do
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
          event.event_id,
          event.content,
          event.origin_server_ts,
          event.room_id,
          event.sender,
          event.type,
          event.state_key
        )
    end
  end

  def generate_event_id_hash(event) do
    event_json =
      Map.from_struct(event)
      |> Map.drop([:hashes, :signatures, :unsigned, :__meta__, :event_state_key, :room])
      |> Jason.encode!()

    "$" <> Base.url_encode64(:crypto.hash(:sha256, event_json), padding: false)
  end

  def generate_event_id do
    "$" <> UUID.uuid4() <> ":" <> @domain
  end

  def get_auth_event_ids(%{type: "m.room.create"} = _event) do
    []
  end

  def get_auth_event_ids(%{type: "m.room.member", state_key: state_key} = event)
      when not is_nil(state_key) do
    event_types = [{"m.room.create", ""}, {"m.room.member", event.sender}]

    event_types =
      if Enum.member?(["join", "invite"], event.content["membership"]) do
        event_types ++ [{"m.room.join_rules", ""}, {"m.room.member", state_key}]
      else
        event_types ++ [{"m.room.member", state_key}]
      end

    from(e in Event,
      where: e.type in ^Enum.map(event_types, fn {type, _state_key} -> type end),
      where: e.state_key in ^Enum.map(event_types, fn {_type, state_key} -> state_key end),
      order_by: [desc: e.depth],
      select: {e.type, e.depth, e.event_id}
    )
    |> Repo.all()
    |> extract_auth_event_ids()
  end

  def get_auth_event_ids(event) do
    from(e in Event,
      where: e.type in ["m.room.create", "m.room.member"],
      where:
        e.state_key ==
          fragment("(case when type = 'm.room.member' then ? else '' end)", ^event.sender),
      order_by: [desc: e.depth],
      select: {e.type, e.depth, e.event_id}
    )
    |> Repo.all()
    |> extract_auth_event_ids()
  end

  defp extract_auth_event_ids(events) do
    events
    |> Enum.group_by(fn {type, _depth, _event_id} -> type end, fn {_type, depth, event_id} ->
      {depth, event_id}
    end)
    |> Enum.map(fn {_type, values} ->
      values |> Enum.max_by(fn {depth, _event_id} -> depth end)
    end)
    |> Enum.sort_by(fn {depth, _event_id} -> depth end)
    |> Enum.reverse()
    |> Enum.map(fn {_depth, event_id} -> event_id end)
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

  def events_in_room_id(room_id, direction, filter, limit, from, to)
      when is_nil(filter) and is_nil(to) do
    base = from(e in Event, where: e.room_id == ^room_id, limit: ^limit)

    query =
      if direction == "f" do
        from(e in base, where: e.origin_server_ts >= ^from, order_by: e.origin_server_ts)
      else
        from(e in base, where: e.origin_server_ts <= ^from, order_by: [desc: e.origin_server_ts])
      end

    # TODO - work on needed state
    events = query |> Repo.all()

    end_ts =
      if Enum.empty?(events) do
        latest_timestamp()
      else
        List.last(events).origin_server_ts
      end

    is_end =
      if direction == "f" do
        from(e in base, where: e.origin_server_ts > ^end_ts) |> Repo.all() |> Enum.empty?()
      else
        from(e in base, where: e.origin_server_ts < ^end_ts) |> Repo.all() |> Enum.empty?()
      end

    if is_end do
      {events, [], nil}
    else
      {events, [], end_ts}
    end
  end

  def events_in_room_id(room_id, direction, filter, limit, from, to) when is_nil(filter) do
    base = from(e in Event, where: e.room_id == ^room_id, limit: ^limit)

    query =
      if direction == "f" do
        from(e in base,
          where: e.origin_server_ts >= ^from,
          where: e.origin_server_ts <= ^to,
          order_by: e.origin_server_ts
        )
      else
        from(e in base,
          where: e.origin_server_ts <= ^from,
          where: e.origin_server_ts >= ^to,
          order_by: [desc: e.origin_server_ts]
        )
      end

    # TODO - work on needed state
    events = query |> Repo.all()

    end_ts =
      if Enum.empty?(events) do
        latest_timestamp()
      else
        List.last(events).origin_server_ts
      end

    is_end =
      if direction == "f" do
        from(e in base, where: e.origin_server_ts > ^end_ts) |> Repo.all() |> Enum.empty?()
      else
        from(e in base, where: e.origin_server_ts < ^end_ts) |> Repo.all() |> Enum.empty?()
      end

    if is_end do
      {events, [], nil}
    else
      {events, [], end_ts}
    end
  end

  def events_in_room_id(room_id, direction, _filter, limit, from, to) when is_nil(to) do
    # TODO - implement filtering
    events_in_room_id(room_id, direction, nil, limit, from, to)
  end

  def events_in_room_id(room_id, direction, _filter, limit, from, to) do
    # TODO - implement filtering
    events_in_room_id(room_id, direction, nil, limit, from, to)
  end

  def latest_timestamp() do
    from(e in Event,
      order_by: [desc: e.origin_server_ts],
      select: e.origin_server_ts,
      limit: 1
    )
    |> Repo.one()
  end

  def find_next_timestamp(timestamp) do
    from(e in Event,
      where: e.origin_server_ts >= ^timestamp,
      order_by: [desc: e.origin_server_ts],
      select: e.origin_server_ts,
      limit: 1
    )
    |> Repo.one()
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

  def send_message(event_params, txn_params) do
    new_depth = get_last_depth(event_params["room_id"]) + 1

    multi =
      Multi.new()
      |> Multi.insert(
        :event,
        Event.changeset(%Event{}, Map.put(event_params, "depth", new_depth))
      )
      |> Multi.run(:transaction, fn _repo, %{event: event} = _changes ->
        Transactions.create_transaction(Map.put(txn_params, "event_id", event.event_id))
      end)

    Repo.transaction(multi)
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

  def create_event(%{"room_id" => room_id} = attrs, type, state_key) when is_nil(state_key) do
    new_depth = Map.get("depth", attrs, get_last_depth(room_id) + 1)

    Map.merge(%{"depth" => new_depth, "type" => type}, attrs)
    |> create_event()
  end

  def create_event(%{"room_id" => room_id} = attrs, type, state_key) do
    new_depth = Map.get("depth", attrs, get_last_depth(room_id) + 1)
    {:ok, _} = find_or_create_state_key(state_key)

    Map.merge(%{"depth" => new_depth, "type" => type, "state_key" => state_key}, attrs)
    |> create_event()
  end

  def create_event(room_id, params, "m.room.topic") do
    {:ok, event_state_key} = find_or_create_state_key("")

    Map.merge(params, %{
      "state_key" => event_state_key.state_key,
      "depth" => get_last_depth(room_id) + 1,
      "type" => "m.room.topic",
      "room_id" => room_id,
      "content" => %{"topic" => params["topic"]}
    })
    |> create_event()
  end

  def create_event(room_id, params, "m.room.name") do
    {:ok, event_state_key} = find_or_create_state_key("")

    Map.merge(params, %{
      "state_key" => event_state_key.state_key,
      "depth" => get_last_depth(room_id) + 1,
      "type" => "m.room.name",
      "content" => %{"name" => params["name"]},
      "room_id" => room_id
    })
    |> create_event()
  end

  def create_event(room_id, params, "m.room.canonical_alias") do
    {:ok, event_state_key} = find_or_create_state_key("")

    Map.merge(params, %{
      "state_key" => event_state_key.state_key,
      "depth" => get_last_depth(room_id) + 1,
      "type" => "m.room.canonical_alias",
      "room_id" => "room_id",
      "content" => %{"alias" => params["room_alias_name"]}
    })
    |> create_event()
  end

  def create_event(room_id, params, "m.room.member", membership) do
    {:ok, event_state_key} = Map.fetch!(params, "state_key") |> find_or_create_state_key()

    Map.merge(params, %{
      "state_key" => event_state_key.state_key,
      "type" => "m.room.member",
      "depth" => get_last_depth(room_id) + 1,
      "content" => %{"membership" => membership},
      "room_id" => room_id
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

  def create_event(attrs, "initial_state") do
    event_state_key = Map.get(attrs, "event_state_key", nil)

    Map.merge(attrs, %{
      "state_key" => event_state_key,
      "depth" => get_last_depth(attrs["room_id"]) + 1
    })
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

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def get_last_depth(room_id) do
    from(e in Event,
      where: e.room_id == ^room_id,
      order_by: [desc: e.depth],
      select: e.depth
    )
    |> first
    |> Repo.one()
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
