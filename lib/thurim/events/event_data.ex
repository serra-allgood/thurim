defmodule Thurim.Events.EventData do
  alias Thurim.Events
  alias Thurim.Federation.KeyServer
  require Logger

  @domain Application.compile_env(:thurim, [:matrix, :domain])

  def base_pdu(event) do
    %{
      "auth_events" => event.auth_events,
      "content" => event.content,
      "depth" => event.depth,
      "hashes" => %{"sha256" => Events.extract_hash_from_id(event.event_id)},
      "origin" => event.origin,
      "origin_server_ts" => event.origin_server_ts,
      "prev_events" => Events.prev_event_ids(event),
      "room_id" => event.room_id,
      "sender" => event.sender,
      "type" => event.type,
      "unsigned" => %{
        "age" => (Timex.now() |> DateTime.to_unix(:millisecond)) - event.origin_server_ts
      }
    }
  end

  def new_pdu(%{state_key: state_key, redacts: redacts} = event)
      when is_nil(state_key) and is_nil(redacts) do
    pdu = base_pdu(event)

    Map.put(pdu, "signatures", %{
      @domain => KeyServer.sign(Map.drop(pdu, "unsigned") |> Jason.encode_to_iodata!())
    })
  end

  def new_pdu(%{state_key: state_key} = event) when is_nil(state_key) do
    pdu = base_pdu(event) |> Map.put("redacts", event.redacts)

    Map.put(pdu, "signatures", %{
      @domain => KeyServer.sign(Map.drop(pdu, "unsigned") |> Jason.encode_to_iodata!())
    })
  end

  def new_pdu(%{redacts: redacts} = event) when is_nil(redacts) do
    pdu = base_pdu(event) |> Map.put("state_key", event.state_key)

    Map.put(pdu, "signatures", %{
      @domain => KeyServer.sign(Map.drop(pdu, "unsigned") |> Jason.encode_to_iodata!())
    })
  end

  def new_pdu(event) do
    msg = "Event with both state_key and redacts not nil should not be possible"

    Logger.error(msg, event: event)

    raise msg
  end

  def base_client(event) do
    %{
      "content" => event.content,
      "event_id" => event.event_id,
      "origin_server_ts" => event.origin_server_ts,
      "room_id" => event.room_id,
      "sender" => event.sender,
      "type" => event.type,
      "unsigned" => %{
        "age" => (Timex.now() |> DateTime.to_unix(:millisecond)) - event.origin_server_ts
      }
    }
  end

  def new_client(%{state_key: state_key} = event) when is_nil(state_key) do
    base_client(event)
  end

  def new_client(event) do
    base_client(event) |> Map.put("state_key", event.state_key)
  end
end
