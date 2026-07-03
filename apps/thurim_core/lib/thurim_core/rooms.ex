defmodule ThurimCore.Rooms do
  import Ecto.Query, warn: false
  import ThurimCore.Utils, only: [then_if: 3]
  alias Ecto.Multi

  alias ThurimCore.{
    Events,
    Events.CurrentStateEvent,
    Events.Event,
    Events.RoomForwardExtremity,
    Rooms.Room,
    Repo
  }

  def all_forward_extremities(room_id) do
    Repo.all(from e in RoomForwardExtremity, where: e.room_id == ^room_id, select: e.event_id)
  end

  def current_state_events(room_id) do
    Repo.all(from s in CurrentStateEvent, where: s.room_id == ^room_id, preload: [:event])
  end

  # params has string keys
  def create_room(params) do
    initial_state = Map.get(params, "initial_state", [])
    invite = Map.get(params, "invite", [])

    multi =
      Multi.new()
      |> Multi.insert(
        :m_room_create,
        Events.build_event("m.room.create", nil, params)
      )
      |> Multi.insert(:room, fn %{m_room_create: event} ->
        Room.create_changeset(%Room{room_id: extract_room_id(event)}, params)
      end)
      |> Multi.insert(:m_room_member, fn %{room: room, m_room_create: prev_event} ->
        Events.build_event("m.room.member", room, params,
          prev_events: [prev_event.event_id],
          depth: prev_event.depth + 1,
          membership: "join"
        )
      end)
      |> Multi.insert(:m_room_power_levels, fn %{room: room, m_room_member: prev_event} ->
        Events.build_event("m.room.power_levels", room, params,
          prev_events: [prev_event.event_id],
          depth: prev_event.depth + 1
        )
      end)
      |> then_if(
        not is_nil(params["room_alias_name"]),
        &Multi.insert(&1, :m_room_canonical_alias, fn %{
                                                        room: room,
                                                        m_room_power_levels: prev_event
                                                      } ->
          Events.build_event("m.room.canonical_alias", room, params,
            prev_events: [prev_event.event_id],
            depth: prev_event.depth + 1
          )
        end)
      )
      |> Multi.insert(:m_room_join_rules, fn %{room: room} = changes ->
        prev_event =
          if Map.has_key?(changes, :m_room_canonical_alias) do
            Map.fetch!(changes, :m_room_canonical_alias)
          else
            Map.fetch!(changes, :m_room_power_levels)
          end

        Events.build_event("m.room.join_rules", room, params,
          prev_events: [prev_event.event_id],
          depth: prev_event.depth + 1
        )
      end)
      |> Multi.insert(:m_room_history_visibility, fn %{room: room, m_room_join_rules: prev_event} ->
        Events.build_event("m.room.history_visibility", room, params,
          prev_events: [prev_event.event_id],
          depth: prev_event.depth + 1
        )
      end)
      |> Multi.insert(:m_room_guest_access, fn %{
                                                 room: room,
                                                 m_room_history_visibility: prev_event
                                               } ->
        Events.build_event("m.room.guest_access", room, params,
          prev_events: [prev_event.event_id],
          depth: prev_event.depth + 1
        )
      end)
      |> then_if(
        not Enum.empty?(initial_state),
        &Enum.reduce(initial_state, &1, fn state_event, multi ->
          Multi.insert(multi, state_event["type"], fn %{room: room} = changes ->
            latest_event = get_latest_event_from_changes(changes)

            Events.build_state_event(state_event["type"], room, Map.merge(params, state_event),
              prev_events: [latest_event.event_id],
              depth: latest_event.depth + 1
            )
          end)
        end)
      )
      |> then_if(
        not is_nil(params["name"]),
        &Multi.insert(&1, :m_room_name, fn %{room: room} = changes ->
          latest_event = get_latest_event_from_changes(changes)

          Events.build_state_event(
            "m.room.name",
            room,
            Map.merge(params, %{"content" => %{"name" => params["name"]}}),
            prev_events: [latest_event.event_id],
            depth: latest_event.depth + 1
          )
        end)
      )
      |> then_if(
        not is_nil(params["topic"]),
        &Multi.insert(&1, :m_room_topic, fn %{room: room} = changes ->
          latest_event = get_latest_event_from_changes(changes)

          Events.build_state_event(
            "m.room.topic",
            room,
            Map.merge(params, %{"content" => %{"name" => params["name"]}}),
            prev_events: [latest_event.event_id],
            depth: latest_event.depth + 1
          )
        end)
      )
      |> then_if(
        not Enum.empty?(invite),
        &Enum.reduce(invite, &1, fn invite, multi ->
          Multi.insert(multi, "invite_#{invite}", fn %{room: room} = changes ->
            latest_event = get_latest_event_from_changes(changes)

            Events.build_event("m.room.member", room, Map.merge(params, %{"state_key" => invite}),
              prev_events: [latest_event.event_id],
              depth: latest_event.depth + 1,
              membership: "invite"
            )
          end)
        end)
      )
      |> Events.insert_event_edges()
      |> Events.project_current_state()

    Repo.transact(multi)
  end

  def extract_room_id(%Event{type: "m.room.create"} = event) do
    "$" <> id = event.event_id
    "!" <> id
  end

  def extract_room_id("$" <> id = event_id) when is_binary(event_id) do
    "!" <> id
  end

  def get_chat_preset(params) do
    default_preset =
      if Map.get(params, "visibility", "private") == "private",
        do: "private_chat",
        else: "public_chat"

    Map.get(
      params,
      "preset",
      default_preset
    )
  end

  def get_latest_event_from_changes(changes) do
    latest_depth =
      Enum.map(changes, fn change -> Map.get(change, :depth, 0) end)
      |> Enum.sort(:desc)
      |> List.first()

    Enum.find(changes, fn change -> change[:depth] == latest_depth end)
  end

  def load_room_version(room_id) do
    from(r in Room, where: r.room_id == ^room_id, select: r.room_version)
    |> Repo.one()
  end
end
