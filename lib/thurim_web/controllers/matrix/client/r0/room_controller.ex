defmodule ThurimWeb.Matrix.Client.R0.RoomController do
  use ThurimWeb, :controller
  use ThurimWeb.Controllers.MatrixController
  alias Thurim.Sync.SyncServer
  alias Thurim.Rooms
  alias Thurim.Events
  alias Thurim.User
  alias Thurim.Transactions

  # Event shape:
  # {
  #   initial_state: Event[],
  #   create_content: "extra keys to be added to the m.room.create event",
  #   preset: private_chat | trusted_private_chat | public_chat,
  #   name?: string
  # }
  def create(conn, params) do
    sender = Map.fetch!(conn.assigns, :sender)

    result =
      Map.put(params, "sender", sender)
      |> Rooms.create_room()

    case result do
      {:ok, %{room: room} = _changes} ->
        SyncServer.add_room(room, sender)
        json(conn, %{room_id: room.room_id})

      {:error, _name, changeset, _changes} ->
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
    sender = Map.fetch!(conn.assigns, :sender)

    if SyncServer.user_in_room?(sender, room_id) do
      response = User.joined_user_ids_in_room(room_id)
      json(conn, %{"joined" => response})
    else
      json_error(conn, :m_forbidden)
    end
  end

  def members(conn, %{"room_id" => room_id} = params) do
    sender = Map.fetch!(conn.assigns, :sender)
    at_time = Map.get(params, "at", :infinity)
    membership = Map.get(params, "membership", nil)
    not_membership = Map.get(params, "not_membership", nil)

    if SyncServer.user_in_room?(sender, room_id) do
      response =
        User.membership_events_in_room(room_id, membership, not_membership, at_time)
        |> Enum.map(&Events.map_event/1)

      json(conn, %{"chunk" => response})
    else
      json_error(conn, :m_forbidden)
    end
  end

  def state(conn, %{"room_id" => room_id} = _params) do
    sender = Map.fetch!(conn.assigns, :sender)

    if SyncServer.user_in_room?(sender, room_id) do
      response = Events.state_events_for_room_id(room_id) |> Enum.map(&Events.map_event/1)
      json(conn, response)
    else
      json_error(conn, :m_forbidden)
    end
  end

  def state_event(
        conn,
        %{"room_id" => room_id, "event_type" => event_type, "state_key" => state_key} = _params
      ) do
    sender = Map.fetch!(conn.assigns, :sender)

    cond do
      SyncServer.user_in_room?(sender, room_id) ->
        case Events.latest_state_event_of_type_in_room_id(room_id, event_type, state_key) do
          nil -> json_error(conn, :m_not_found)
          event -> json(conn, event.content)
        end

      Events.user_previously_in_room?(sender, room_id) ->
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
        %{"room_id" => room_id, "event_type" => event_type, "state_key" => state_key} = _params
      ) do
    sender = Map.fetch!(conn.assigns, :sender)
    device = Map.fetch!(conn.assigns, :current_device)

    if User.permission_to_create_event?(sender, room_id, event_type, true) do
      case Events.create_event(
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
        {:ok, event} ->
          SyncServer.append_state_event(sender, device, room_id, event)
          json(conn, %{"event_id" => event.event_id})

        {:error, _name, changeset, _changes} ->
          send_changeset_error_to_json(conn, changeset)
      end
    else
      json_error(conn, :m_forbidden)
    end
  end

  def messages(conn, %{"room_id" => room_id, "dir" => dir} = params) do
    account = Map.fetch!(conn.assigns, :current_account)
    sender = Map.fetch!(conn.assigns, :sender)

    limit = Map.get(params, "limit", 10)
    filter = Map.get(params, "filter", nil) |> get_filter(account)
    from = Map.get(params, "from", nil)
    to = Map.get(params, "to", nil)

    from =
      if from == nil do
        Events.latest_timestamp()
      else
        String.to_integer(from)
      end

    to =
      if to == nil do
        nil
      else
        String.to_integer(to)
      end

    if SyncServer.user_in_room?(sender, room_id) do
      {chunk, state, end_token} = Events.events_in_room_id(room_id, dir, filter, limit, from, to)

      response =
        if end_token != nil do
          %{
            "chunk" => chunk |> Enum.map(&Events.map_event/1),
            "start" => Integer.to_string(from),
            "end" => Integer.to_string(end_token),
            "state" => state |> Enum.map(&Events.map_event/1)
          }
        else
          %{
            "chunk" => chunk |> Enum.map(&Events.map_event/1),
            "start" => from,
            "state" => state |> Enum.map(&Events.map_event/1)
          }
        end

      json(conn, response)
    else
      json_error(conn, :m_forbidden)
    end
  end

  def send_message(
        conn,
        %{"room_id" => room_id, "event_type" => event_type, "txn_id" => txn_id} = _params
      ) do
    account = Map.fetch!(conn.assigns, :current_account)
    sender = Map.fetch!(conn.assigns, :sender)
    device = Map.fetch!(conn.assigns, :current_device)

    txn =
      Transactions.get(
        localpart: account.localpart,
        device_id: device.device_id,
        transaction_id: txn_id
      )

    cond do
      txn != nil ->
        json(conn, %{event_id: txn.event_id})

      SyncServer.user_in_room?(sender, room_id) ->
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
                SyncServer.append_event(sender, device, room_id, event)
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
