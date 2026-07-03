defmodule ThurimCore.Events do
  import Ecto.Query, warn: false
  import ThurimCore.Utils, only: [then_if: 3]

  alias Ecto.Multi

  alias ThurimCore.{
    Events.CurrentStateEvent,
    Events.Event,
    Events.EventAuth,
    Events.EventEdge,
    Keys.SigningKeyStore,
    MatrixConfig,
    Repo,
    Rooms,
    Rooms.Room
  }

  defp base_build_event(event, room_version) do
    signing_key = SigningKeyStore.active_key()

    event
    |> hash_and_sign_event(
      signing_key.private_key,
      MatrixConfig.server_name(),
      signing_key.key_id
    )
    |> put_event_id(room_version)
  end

  def build_event(type, room, params, options \\ [])

  def build_event(
        "m.room.canonical_alias" = type,
        room,
        %{"sender" => sender, "room_alias_name" => room_alias} = params,
        options
      ) do
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)

    %{
      "auth_events" => select_auth_events(room, sender),
      "prev_events" => prev_events,
      "type" => type,
      "state_key" => "",
      "room_id" => room.room_id,
      "depth" => depth,
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => %{
        "alias" => room_alias,
        "alt_aliases" => []
      }
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  # TODO: Implement guest users?
  def build_event(
        "m.room.guest_access" = type,
        %Room{} = room,
        %{"sender" => sender} = _params,
        options
      ) do
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)

    %{
      "auth_events" => select_auth_events(room, sender),
      "prev_events" => prev_events,
      "room_id" => room.room_id,
      "type" => type,
      "state_key" => "",
      "depth" => depth,
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => %{
        "guest_access" => "forbidden"
      }
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  def build_event(
        "m.room.history_visibility" = type,
        %Room{} = room,
        %{"sender" => sender} = _params,
        options
      ) do
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)
    history_visibility = Keyword.get(options, :history_visibility, "shared")

    %{
      "auth_events" => select_auth_events(room, sender),
      "prev_events" => prev_events,
      "room_id" => room.room_id,
      "type" => type,
      "state_key" => "",
      "depth" => depth,
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => %{
        "history_visibility" => history_visibility
      }
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  def build_event(
        "m.room.join_rules" = type,
        %Room{} = room,
        %{"sender" => sender} = params,
        options
      ) do
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)
    preset = Rooms.get_chat_preset(params)

    join_rule =
      case preset do
        "private_chat" -> "invite"
        "trusted_private_chat" -> "invite"
        "public_chat" -> "public"
      end

    %{
      "auth_events" => select_auth_events(room, sender),
      "prev_events" => prev_events,
      "room_id" => room.room_id,
      "type" => type,
      "state_key" => "",
      "depth" => depth,
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      # TODO: Implement restricted rooms
      "content" => %{
        "allow" => [],
        "join_rule" => join_rule
      }
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  def build_event(
        "m.room.create" = type,
        nil = _room,
        %{"sender" => sender, "room_version" => room_version} = params,
        _options
      ) do
    %{
      "auth_events" => [],
      "prev_events" => [],
      "type" => "m.room.create",
      "state_key" => "",
      "depth" => 0,
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => build_event_content(type, params, room_version: room_version)
    }
    |> base_build_event(room_version)
    |> then(&Map.merge(&1, %{"room_id" => Rooms.extract_room_id(&1["event_id"])}))
    |> then(&Event.changeset(%Event{}, &1))
  end

  def build_event(
        "m.room.member" = type,
        %Room{} = room,
        %{"sender" => sender} = params,
        options
      ) do
    membership = Keyword.fetch!(options, :membership)
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)

    %{
      "auth_events" =>
        select_auth_events(room, sender, %{
          membership: membership,
          target_user: params["state_key"] || sender
        }),
      "prev_events" => prev_events,
      "room_id" => room.room_id,
      "type" => "m.room.member",
      "depth" => depth,
      "state_key" => if(membership == "join", do: sender, else: params["state_key"]),
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => build_event_content(type, params, membership: membership)
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  def build_event(
        "m.room.power_levels" = type,
        %Room{} = room,
        %{"sender" => sender} = params,
        options
      ) do
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)

    %{
      "auth_events" => select_auth_events(room, sender),
      "prev_events" => prev_events,
      "room_id" => room.room_id,
      "type" => type,
      "depth" => depth,
      "state_key" => "",
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => build_event_content(type, params)
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  def build_event_content(type, params, options \\ [])

  # build_event_content for m.room.create
  # 1. Get client-sent creation_content, which can be empty.
  # If it's empty, default to federation
  #
  # 2. Get chat preset, which can be empty. Defaults to "private_chat"
  # If preset is "trusted_private_chat", creation_content["additional_creators"] is the union
  # of creation_content["additional_creators"] and params["invites"]
  #
  # 3. Finally, override whatever room_version was sent with the actual room_version
  def build_event_content("m.room.create", params, options) do
    room_version = Keyword.fetch!(options, :room_version)
    creation_content = Map.get(params, "creation_content", %{"m.federate" => true})
    preset = Rooms.get_chat_preset(params)

    creation_content =
      if preset == "trusted_private_chat" do
        invite =
          Map.get(params, "invite", [])
          |> MapSet.new()

        additional_creators =
          Map.get(creation_content, "additional_creators", [])
          |> MapSet.new()

        Map.put(
          creation_content,
          "additional_creators",
          MapSet.union(invite, additional_creators)
        )
      else
        creation_content
      end

    Map.put(creation_content, "room_version", room_version)
  end

  def build_event_content("m.room.member", params, options) do
    membership = Keyword.fetch!(options, :membership)

    %{
      "membership" => membership,
      "is_direct" => params["is_direct"] || false,
      "displayname" => params["displayname"]
    }
    |> then_if(not (params["reason"] |> is_nil()), &Map.put(&1, "reason", params["reason"]))
    |> then_if(
      not (params["avatar_url"] |> is_nil()),
      &Map.put(&1, "avatar_url", params["avatar_url"])
    )
  end

  # TODO: Handle room v11 with its use of users for the room creator
  def build_event_content("m.room.power_levels", params, _options) do
    power_level_content_override = Map.get(params, "power_level_content_override", %{})

    MatrixConfig.default_power_levels()
    |> Map.merge(power_level_content_override)
  end

  def build_state_event(
        type,
        %Room{} = room,
        %{"sender" => sender, "content" => content} = params,
        options
      ) do
    prev_events = Keyword.fetch!(options, :prev_events)
    depth = Keyword.fetch!(options, :depth)

    %{
      "auth_events" => select_auth_events(room, sender),
      "prev_events" => prev_events,
      "type" => type,
      "state_key" => Map.get(params, "state_key", ""),
      "room_id" => room.room_id,
      "depth" => depth,
      "origin_server_ts" => DateTime.utc_now(:millisecond),
      "sender" => sender,
      "content" => content
    }
    |> base_build_event(room.room_version)
    |> then(&Event.changeset(%Event{}, &1))
  end

  def content_hash(event) do
    event
    |> Map.drop(~w(unsigned signature hashes))
    |> Jcs.encode()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  def event_id(event, room_version) do
    "$" <> reference_hash(event, room_version)
  end

  @doc """
  Signs an event:
  1. Compute content hash, add to event["hashes"]
  2. Redact the event (strip non-essential keys)
  3. Remove signatures/unsigned
  4. Canonical JSON → ed25519 sign → unpadded base64
  5. Add signature back to original event
  """
  def hash_and_sign_event(event, signing_key, server_name, key_id) do
    # Step 1: content hash
    hashed_event = Map.put(event, "hashes", %{sha256: content_hash(event)})

    # Step 2-4: sign the redacted skeleton
    sig_bytes =
      hashed_event
      |> ThurimCore.Redaction.redact(
        hashed_event["room_version"] || ThurimCore.MatrixConfig.default_room_version()
      )
      |> Map.drop(~w(signatures unsigned))
      |> Jcs.encode()
      |> then(&:crypto.sign(:eddsa, :none, &1, [signing_key, :ed25519]))

    sig_b64 = Base.url_encode64(sig_bytes, padding: false)

    # Step 5: merge signature into the hashed event
    key_identifier = "ed25519:#{key_id}"

    Map.update(
      hashed_event,
      "signatures",
      %{server_name => %{key_identifier => sig_b64}},
      fn sigs -> Map.put(sigs, server_name, %{key_identifier => sig_b64}) end
    )
  end

  def insert_event_edges(multi) do
    Multi.run(multi, :insert_event_edges, fn _repo, changes ->
      Enum.filter(changes, fn change ->
        not is_nil(change[:event_id])
      end)
      |> Enum.reduce(multi, fn event_change, multi ->
        multi =
          Enum.reduce(event_change.prev_events, multi, fn prev_event_id, multi ->
            Multi.insert(
              multi,
              "insert_prev_event_edge_#{prev_event_id}_for_#{event_change.event_id}}",
              EventEdge.changeset(%EventEdge{}, %{
                prev_event_id: prev_event_id,
                event_id: event_change.event_id
              })
            )
          end)

        Enum.reduce(event_change.auth_events, multi, fn auth_event_id, multi ->
          Multi.insert(
            multi,
            "insert_auth_event_#{auth_event_id}_for_#{event_change.event_id}",
            EventAuth.changeset(%EventAuth{}, %{
              event_id: event_change.event_id,
              auth_event_id: auth_event_id
            })
          )
        end)
      end)

      {:ok, nil}
    end)
  end

  def project_current_state(multi) do
    Multi.run(multi, :project_current_state, fn _repo, changes ->
      Enum.filter(changes, fn change -> not is_nil(change[:state_key]) end)
      |> Enum.reduce(multi, fn state_event, multi ->
        Multi.run(multi, "project_current_state_for_#{state_event.event_id}", fn _repo,
                                                                                 _changes ->
          case Repo.get_by(CurrentStateEvent,
                 room_id: state_event.room_id,
                 type: state_event.type,
                 state_key: state_event.state_key
               ) do
            nil ->
              %CurrentStateEvent{
                room_id: state_event.room_id,
                type: state_event.type,
                state_key: state_event.state_key
              }

            current_state_event ->
              current_state_event
          end
          |> CurrentStateEvent.changeset(%{event_id: state_event.event_id})
          |> Repo.insert_or_update()
        end)
      end)

      {:ok, nil}
    end)
  end

  def put_event_id(event, room_version) do
    Map.put(event, "event_id", event_id(event, room_version))
  end

  @doc """
  Computes the reference hash (event ID body) per spec:
  redact → remove signatures/unsigned → canonical JSON → SHA-256 → unpadded base64.
  """
  def reference_hash(event, room_version) do
    event
    |> ThurimCore.Redaction.redact(room_version)
    |> Map.drop(~w(signatures unsigned))
    |> Jcs.encode()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  # See https://spec.matrix.org/v1.18/server-server-api/#auth-events-selection
  # for auth event slection. The membership_change param is only necessary for state
  # events of type m.room.member.
  def select_auth_events(%Room{} = room, sender, membership_change \\ nil) do
    from(se in CurrentStateEvent,
      where:
        (se.room_id == ^room.room_id and se.type == "m.room.power_levels" and se.state_key == "") or
          (se.room_id == ^room.room_id and se.type == "m.room.member" and se.state_key == ^sender)
    )
    |> then_if(
      not is_nil(membership_change),
      &from(se in &1,
        or_where:
          se.room_id == ^room.room_id and se.type == "m.room.member" and
            se.state_key == ^membership_change.target_user
      )
    )
    |> then_if(
      not is_nil(membership_change) and
        Enum.member?(~w(join invite knock), membership_change.membership),
      &from(se in &1,
        or_where:
          se.room_id == ^room.room_id and se.type == "m.room.join_rules" and se.state_key == ""
      )
    )
    |> then(&from(se in &1, select: se.event_id))
    |> Repo.all()
  end

  @doc """
  Verifies that server_name has signed the event.
  """
  def verify_event_signature(event, server_name, key_id, verify_key) do
    key_identifier = "ed25519:#{key_id}"
    sig_b64 = get_in(event, ["signatures", server_name, key_identifier])

    with {:ok, sig_bytes} <- Base.url_decode64(sig_b64 || "", padding: false),
         signed_bytes =
           event
           |> ThurimCore.Redaction.redact(
             event["room_version"] || ThurimCore.MatrixConfig.default_room_version()
           )
           |> Map.drop(["signatures", "unsigned"])
           |> Jcs.encode(),
         true <- :crypto.verify(:eddsa, :none, signed_bytes, sig_bytes, [verify_key, :ed25519]) do
      :ok
    else
      _ -> {:error, :invalid_signature}
    end
  end
end
