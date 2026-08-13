defmodule ThurimCore.Sync do
  import Ecto.Query, warn: false

  alias ThurimCore.{
    Events.CurrentStateEvent,
    Events.Event,
    Repo,
    Sync.Notifier
  }

  @default_limit 10
  @max_limit 1000
  @default_timeout 0
  @max_timeout 120_000
  def sync(user_id, opts \\ []) do
    with {:ok, since} <- parse_since(Keyword.get(opts, :since)),
         {:ok, limit} <- parse_limit(Keyword.get(opts, :limit)),
         {:ok, timeout_ms} <- parse_timeout(Keyword.get(opts, :timeout)) do
      deadline = System.monotonic_time(:millisecond) + timeout_ms
      device_id = Keyword.get(opts, :device_id)

      {response, subscribed_topics} =
        wait_for_sync(user_id, device_id, since, limit, deadline, MapSet.new())

      Enum.each(subscribed_topics, &Notifier.unsubscribe/1)
      {:ok, response}
    end
  end

  defp wait_for_sync(user_id, device_id, since, limit, deadline, subscribed_topics) do
    {response, has_updates, joined_room_ids} = build_sync_response(user_id, since, limit)
    desired_topics = sync_topics(user_id, device_id, joined_room_ids) |> MapSet.new()
    subscribed_topics = reconcile_subscriptions(subscribed_topics, desired_topics)

    cond do
      has_updates ->
        {response, subscribed_topics}

      System.monotonic_time(:millisecond) >= deadline ->
        {response, subscribed_topics}

      true ->
        remaining_ms = max(deadline - System.monotonic_time(:millisecond), 0)

        receive do
          :sync_update ->
            wait_for_sync(user_id, device_id, since, limit, deadline, subscribed_topics)

          _ ->
            wait_for_sync(user_id, device_id, since, limit, deadline, subscribed_topics)
        after
          remaining_ms ->
            {response, subscribed_topics}
        end
    end
  end

  defp build_sync_response(user_id, since, limit) do
    joined_room_ids = joined_room_ids(user_id)
    invited_room_ids = invited_room_ids(user_id)

    {join_rooms, max_join_stream} =
      Enum.reduce(joined_room_ids, {%{}, since}, fn room_id, {acc, max_seen} ->
        room_timeline =
          room_timeline(room_id, since, limit)
          |> Enum.map(&event_to_client_json/1)

        room_state =
          room_state(room_id)
          |> Enum.map(&event_to_client_json/1)

        room_max_stream =
          room_timeline
          |> Enum.map(&Map.fetch!(&1, "stream_ordering"))
          |> Enum.max(fn -> since end)

        room_payload = %{
          "timeline" => %{
            "events" => room_timeline,
            "limited" => false,
            "prev_batch" => encode_stream_token(since)
          },
          "state" => %{
            "events" => room_state
          },
          "ephemeral" => %{"events" => []},
          "account_data" => %{"events" => []},
          "unread_notifications" => %{
            "highlight_count" => 0,
            "notification_count" => 0
          }
        }

        {
          Map.put(acc, room_id, room_payload),
          max(max_seen, room_max_stream)
        }
      end)

    {invite_rooms, max_invite_stream} =
      Enum.reduce(invited_room_ids, {%{}, since}, fn room_id, {acc, max_seen} ->
        invite_state_events =
          room_state(room_id)
          |> Enum.map(&event_to_client_json/1)

        room_max_stream =
          invite_state_events
          |> Enum.map(&Map.fetch!(&1, "stream_ordering"))
          |> Enum.max(fn -> since end)

        room_payload = %{
          "invite_state" => %{
            "events" => invite_state_events
          }
        }

        {
          Map.put(acc, room_id, room_payload),
          max(max_seen, room_max_stream)
        }
      end)

    max_seen_stream = max(max_join_stream, max_invite_stream)

    response = %{
      "next_batch" => encode_stream_token(max_seen_stream),
      "rooms" => %{
        "join" => join_rooms,
        "invite" => invite_rooms,
        "leave" => %{}
      },
      "presence" => %{"events" => []},
      "to_device" => %{"events" => []},
      "account_data" => %{"events" => []},
      "device_lists" => %{"changed" => [], "left" => []},
      "device_one_time_keys_count" => %{}
    }

    has_updates = max_seen_stream > since
    {response, has_updates, joined_room_ids}
  end

  defp joined_room_ids(user_id) do
    from(current_state in CurrentStateEvent,
      join: event in Event,
      on: event.event_id == current_state.event_id,
      where:
        current_state.type == "m.room.member" and
          current_state.state_key == ^user_id and
          fragment("?->>? = ?", event.content, "membership", "join"),
      select: current_state.room_id
    )
    |> Repo.all()
  end

  defp invited_room_ids(user_id) do
    from(current_state in CurrentStateEvent,
      join: event in Event,
      on: event.event_id == current_state.event_id,
      where:
        current_state.type == "m.room.member" and
          current_state.state_key == ^user_id and
          fragment("?->>? = ?", event.content, "membership", "invite"),
      select: current_state.room_id
    )
    |> Repo.all()
  end

  defp sync_topics(user_id, device_id, joined_room_ids) do
    room_topics = Enum.map(joined_room_ids, &Notifier.room_topic/1)
    user_topics = [Notifier.user_topic(user_id)]

    device_topics =
      if is_binary(device_id) and device_id != "",
        do: [Notifier.device_topic(device_id)],
        else: []

    room_topics ++ user_topics ++ device_topics
  end

  defp reconcile_subscriptions(subscribed, desired) do
    to_subscribe = MapSet.difference(desired, subscribed)
    to_unsubscribe = MapSet.difference(subscribed, desired)

    Enum.each(to_subscribe, &Notifier.subscribe/1)
    Enum.each(to_unsubscribe, &Notifier.unsubscribe/1)

    desired
  end

  defp room_timeline(room_id, since, limit) do
    from(event in Event,
      where: event.room_id == ^room_id and event.stream_ordering > ^since,
      order_by: [asc: event.stream_ordering],
      limit: ^limit
    )
    |> Repo.all()
  end

  defp room_state(room_id) do
    from(current_state in CurrentStateEvent,
      join: event in Event,
      on: event.event_id == current_state.event_id,
      where: current_state.room_id == ^room_id,
      order_by: [asc: event.stream_ordering],
      select: event
    )
    |> Repo.all()
  end

  defp event_to_client_json(event) do
    %{
      "event_id" => event.event_id,
      "room_id" => event.room_id,
      "sender" => event.sender,
      "type" => event.type,
      "state_key" => event.state_key,
      "content" => event.content,
      "origin_server_ts" => event.origin_server_ts,
      "unsigned" => event.unsigned || %{},
      "stream_ordering" => event.stream_ordering
    }
  end

  defp encode_stream_token(stream_ordering) do
    "s#{stream_ordering}"
  end

  defp parse_since(nil), do: {:ok, 0}
  defp parse_since(""), do: {:ok, 0}
  defp parse_since("s" <> rest), do: parse_integer(rest, :invalid_since)
  defp parse_since(since), do: parse_integer(since, :invalid_since)

  defp parse_limit(nil), do: {:ok, @default_limit}
  defp parse_limit(""), do: {:ok, @default_limit}

  defp parse_limit(limit) when is_integer(limit) do
    cond do
      limit < 1 -> {:error, :invalid_limit}
      limit > @max_limit -> {:ok, @max_limit}
      true -> {:ok, limit}
    end
  end

  defp parse_limit(limit) do
    with {:ok, parsed_limit} <- parse_integer(limit, :invalid_limit) do
      parse_limit(parsed_limit)
    end
  end

  defp parse_timeout(nil), do: {:ok, @default_timeout}
  defp parse_timeout(""), do: {:ok, @default_timeout}

  defp parse_timeout(timeout) when is_integer(timeout) do
    cond do
      timeout < 0 -> {:error, :invalid_timeout}
      timeout > @max_timeout -> {:ok, @max_timeout}
      true -> {:ok, timeout}
    end
  end

  defp parse_timeout(timeout) do
    with {:ok, parsed_timeout} <- parse_integer(timeout, :invalid_timeout) do
      parse_timeout(parsed_timeout)
    end
  end

  defp parse_integer(value, error_type) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed >= 0 -> {:ok, parsed}
      _ -> {:error, error_type}
    end
  end

  defp parse_integer(_value, error_type), do: {:error, error_type}
end
