defmodule ThurimWeb.Matrix.Client.V3.RoomController do
  require Logger
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController

  alias Thurim.{
    Events,
    Rooms,
    Rooms.RoomMembership,
    Rooms.RoomSupervisor,
    Rooms.RoomServer,
    Sync.SyncServer,
    Sync.SyncToken,
    User,
    Transactions
  }

  # TODO: Fully implement
  def aliases(conn, %{"room_id" => _room_id} = _params) do
    json(conn, %{"aliases" => []})
  end

  def index(conn, params) do
    server = Map.get(params, "server")
    limit = Map.get(params, "limit")
    since = Map.get(params, "since")
    response = Rooms.public_rooms(server, limit, since)
    json(conn, response)
  end

  def public_rooms(conn, params) do
    server = Map.get(params, "server")
    limit = Map.get(params, "limit")
    since = Map.get(params, "since")
    response = Rooms.public_rooms(server, limit, since)
    json(conn, response)
  end

  def leave(conn, %{"room_id" => room_id} = _params) do
    %{sender: sender} = conn.assigns

    attrs = %{"room_id" => room_id, "event_state_key" => sender, "sender" => sender}

    with {:ok, _} <- Events.create_event(attrs, "m.room.member", "leave") do
      RoomServer.notify_listeners(room_id)
      SyncServer.notify_listeners()
      json(conn, %{})
    else
      {:error, changeset} ->
        Logger.error("Failed to leave room: #{inspect(changeset, pretty: true)}")
        send_changeset_error_to_json(conn, changeset)
    end
  end

  def join(conn, %{"room_id_or_alias" => room_id_or_alias} = _params) do
    %{sender: sender} = conn.assigns

    room_id =
      if String.starts_with?(room_id_or_alias, "#"),
        do: Rooms.id_from_alias(room_id_or_alias),
        else: room_id_or_alias

    attrs = %{"room_id" => room_id, "event_state_key" => sender, "sender" => sender}

    with true <- RoomMembership.can_join?(sender, room_id),
         {:ok, _} <- Events.create_event(attrs, "m.room.member", "join") do
      if !RoomServer.exists?(room_id) do
        RoomSupervisor.start_room(room_id)
      end

      RoomServer.notify_listeners(room_id)
      SyncServer.notify_listeners()
      json(conn, %{room_id: room_id})
    else
      false ->
        json_error(conn, :m_forbidden)

      {:error, errors} ->
        Logger.error("Failed to join room due to errors: #{inspect(errors, pretty: true)}")
        send_changeset_error_to_json(conn, errors)
    end
  end

  # Event shape:
  # {
  #   initial_state: Event[],
  #   create_content: "extra keys to be added to the m.room.create event",
  #   preset: private_chat | trusted_private_chat | public_chat,
  #   name?: string
  # }
  def create(conn, params) do
    %{sender: sender} = conn.assigns

    result =
      Map.put(params, "sender", sender)
      |> Rooms.create_room()

    case result do
      {:ok, %{room: room} = _changes} ->
        RoomSupervisor.start_room(room.room_id)
        RoomServer.notify_listeners(room.room_id)
        SyncServer.notify_listeners()
        json(conn, %{room_id: room.room_id})

      {:error, _step, changeset} ->
        send_changeset_error_to_json(conn, changeset)
    end
  end

  def get_event(conn, %{"room_id" => room_id, "event_id" => event_id} = _params) do
    case Events.get_by(room_id: room_id, event_id: event_id) do
      nil ->
        json_error(conn, :m_not_found)

      event when is_nil(event.state_key) ->
        json(conn, %{
          content: event.content,
          event_id: event.event_id,
          origin_server_ts: event.origin_server_ts,
          room_id: event.room_id,
          sender: event.sender,
          type: event.type
        })

      event ->
        json(conn, %{
          content: event.content,
          event_id: event.event_id,
          origin_server_ts: event.origin_server_ts,
          room_id: event.room_id,
          sender: event.sender,
          type: event.type,
          state_key: event.state_key
        })
    end
  end

  def joined_members(conn, %{"room_id" => room_id} = _params) do
    %{sender: sender} = conn.assigns

    if RoomMembership.in_room?(sender, room_id) do
      response = RoomMembership.joined_user_ids_in_room(room_id)
      json(conn, %{"joined" => response})
    else
      json_error(conn, :m_forbidden)
    end
  end

  def members(conn, %{"room_id" => room_id} = params) do
    %{sender: sender} = conn.assigns
    at_time = Map.get(params, "at", :infinity)

    at_time =
      if is_binary(at_time) do
        SyncToken.extract_pdu_token(at_time)
      else
        at_time
      end

    membership = Map.get(params, "membership")
    not_membership = Map.get(params, "not_membership")

    if RoomMembership.in_room?(sender, room_id) do
      response =
        RoomMembership.membership_events_in_room(room_id, membership, not_membership, at_time)
        |> Enum.map(&Events.map_client_event/1)

      json(conn, %{"chunk" => response})
    else
      json_error(conn, :m_forbidden)
    end
  end

  def state(conn, %{"room_id" => room_id} = _params) do
    %{sender: sender} = conn.assigns

    if RoomMembership.in_room?(sender, room_id) do
      response =
        Events.state_events_for_room_id(room_id, nil) |> Enum.map(&Events.map_client_event/1)

      json(conn, response)
    else
      json_error(conn, :m_forbidden)
    end
  end

  def state_event(
        conn,
        %{"room_id" => room_id, "event_type" => event_type, "state_key" => state_key} = _params
      ) do
    %{sender: sender} = conn.assigns

    cond do
      RoomMembership.in_room?(sender, room_id) ->
        case Events.latest_state_event_of_type_in_room_id(room_id, event_type, state_key) do
          nil -> json_error(conn, :m_not_found)
          event -> json(conn, event.content)
        end

      RoomMembership.previously_in_room?(sender, room_id) ->
        leave_event =
          Events.latest_state_event_of_type_in_room_id(room_id, "m.room.member", sender)

        case Events.latest_state_event_of_type_in_room_id(
               room_id,
               event_type,
               state_key,
               leave_event.origin_server_ts
             ) do
          nil -> json_error(conn, :m_not_found)
          event -> json(conn, event.content)
        end
    end
  end

  def create_state_event(
        conn,
        %{"room_id" => room_id, "event_type" => event_type} = params
      ) do
    %{sender: sender} = conn.assigns
    state_key = Map.get(params, "state_key", "")

    with {:has_permission, true} <-
           {:has_permission, User.permission_to_create_event?(sender, room_id, event_type, true)},
         {:ok, event} <-
           Events.create_event(
             %{
               "sender" => sender,
               "content" => conn.body_params,
               "room_id" => room_id,
               "type" => event_type,
               "state_key" => state_key
             },
             event_type,
             state_key
           ) do
      RoomServer.notify_listeners(room_id)
      SyncServer.notify_listeners()
      json(conn, %{"event_id" => event.event_id})
    else
      {:has_permission, false} -> json_error(conn, :m_forbidden)
      {:error, errors} -> send_changeset_error_to_json(conn, errors)
    end
  end

  def create_state_event(conn, params),
    do: create_state_event(conn, Map.put(params, "state_key", ""))

  def messages(conn, %{"room_id" => room_id, "dir" => dir} = params) do
    %{current_account: account, sender: sender} = conn.assigns

    limit = Map.get(params, "limit", 10)
    filter = Map.get(params, "filter", nil) |> get_filter(account)
    from = Map.get(params, "from", nil)
    to = Map.get(params, "to", nil)

    from =
      if is_nil(from) do
        Events.max_pdu_count()
      else
        String.to_integer(from)
      end

    to =
      if is_nil(to) do
        nil
      else
        String.to_integer(to)
      end

    if RoomMembership.in_room?(sender, room_id) do
      {chunk, state, end_token} = Events.events_in_room_id(room_id, dir, filter, limit, from, to)

      response =
        if end_token != nil do
          %{
            "chunk" => chunk |> Enum.map(&Events.map_client_event/1),
            "start" => Integer.to_string(from),
            "end" => Integer.to_string(end_token),
            "state" => state |> Enum.map(&Events.map_client_event/1)
          }
        else
          %{
            "chunk" => chunk |> Enum.map(&Events.map_client_event/1),
            "start" => from,
            "state" => state |> Enum.map(&Events.map_client_event/1)
          }
        end

      json(conn, response)
    else
      json_error(conn, :m_forbidden)
    end
  end

  def create_redaction(
        conn,
        %{"room_id" => room_id, "event_id" => _event_id, "txn_id" => txn_id} = _params
      ) do
    %{current_account: account, sender: sender, current_device: device} = conn.assigns

    txn =
      Transactions.get(
        localpart: account.localpart,
        device_id: device.device_id,
        transaction_id: txn_id
      )

    cond do
      txn != nil ->
        json(conn, %{event_id: txn.event_id})

      RoomMembership.in_room?(sender, room_id) ->
        json_error(conn, :t_not_implemented)

      true ->
        json_error(conn, :t_not_implemented)
    end
  end

  def send_message(
        conn,
        %{"room_id" => room_id, "event_type" => event_type, "txn_id" => txn_id} = _params
      ) do
    %{current_account: account, sender: sender, current_device: device} = conn.assigns

    txn =
      Transactions.get(
        localpart: account.localpart,
        device_id: device.device_id,
        transaction_id: txn_id
      )

    cond do
      !is_nil(txn) ->
        json(conn, %{event_id: txn.event_id})

      RoomMembership.in_room?(sender, room_id) ->
        case Jason.encode(conn.body_params) do
          {:ok, _} ->
            event_params = %{
              "room_id" => room_id,
              "sender" => sender,
              "content" => conn.body_params,
              "type" => event_type
            }

            txn_params = %{
              "localpart" => account.localpart,
              "device_id" => device.device_id,
              "transaction_id" => txn_id
            }

            case Events.send_message(event_params, txn_params) do
              {:ok, %{event: event} = _changes} ->
                RoomServer.notify_listeners(room_id)
                json(conn, %{event_id: event.event_id})

              {:error, _name, changeset, _changes} ->
                send_changeset_error_to_json(conn, changeset)
            end

          {:error, _} ->
            json_error(conn, :m_bad_type)
        end
    end
  end
end
