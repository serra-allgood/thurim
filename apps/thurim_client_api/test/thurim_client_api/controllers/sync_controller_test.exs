defmodule ThurimClientApi.SyncControllerTest do
  use ThurimClientApi.ConnCase, async: true

  import Ecto.Query

  alias ThurimCore.{
    Events.Event,
    Repo,
    Rooms
  }

  @user_id "@alice:localhost"

  test "returns joined rooms and timeline events on initial sync", %{conn: conn} do
    {:ok, room} = create_room_for(@user_id)

    conn =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{})

    response = json_response(conn, 200)

    assert response["next_batch"] =~ "s"
    assert Map.has_key?(response["rooms"]["join"], room.room_id)
    assert response["presence"] == %{"events" => []}

    room_sync = response["rooms"]["join"][room.room_id]
    assert room_sync["timeline"]["limited"] == false
    assert length(room_sync["timeline"]["events"]) > 0
    assert room_sync["state"]["events"] |> is_list()
  end

  test "respects since token for incremental sync", %{conn: conn} do
    {:ok, room} = create_room_for(@user_id)

    first_sync =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{})
      |> json_response(200)

    since = first_sync["next_batch"]
    insert_room_message_event(room.room_id, @user_id)

    second_sync =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{"since" => since})
      |> json_response(200)

    timeline_events = second_sync["rooms"]["join"][room.room_id]["timeline"]["events"]

    assert Enum.map(timeline_events, & &1["type"]) == ["m.room.message"]
    assert hd(timeline_events)["content"]["body"] == "hello from sync test"
  end

  test "returns bad request for invalid since token", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{"since" => "not-a-token"})

    assert %{
             "errcode" => "M_INVALID_PARAM"
           } = json_response(conn, 400)
  end

  test "returns bad request for invalid timeout", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{"timeout" => "invalid"})

    assert %{
             "errcode" => "M_INVALID_PARAM"
           } = json_response(conn, 400)
  end

  test "honors timeout when no new events are available", %{conn: conn} do
    {:ok, _room} = create_room_for(@user_id)

    first_sync =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{})
      |> json_response(200)

    since = first_sync["next_batch"]
    timeout_ms = 30
    started_at = System.monotonic_time(:millisecond)

    response =
      conn
      |> assign(:current_user, %{user_id: @user_id})
      |> ThurimClientApi.SyncController.sync(%{"since" => since, "timeout" => "#{timeout_ms}"})
      |> json_response(200)

    elapsed_ms = System.monotonic_time(:millisecond) - started_at

    assert elapsed_ms >= timeout_ms - 5
    assert response["next_batch"] == since
  end

  defp create_room_for(user_id) do
    Rooms.create_room(%{
      "creator" => user_id,
      "sender" => user_id,
      "room_version" => "v12"
    })
  end

  defp insert_room_message_event(room_id, user_id) do
    parent_event =
      from(event in Event,
        where: event.room_id == ^room_id,
        order_by: [desc: event.depth],
        limit: 1
      )
      |> Repo.one!()

    Event.changeset(%Event{}, %{
      "event_id" => "$sync-test-#{System.unique_integer([:positive])}",
      "room_id" => room_id,
      "sender" => user_id,
      "type" => "m.room.message",
      "content" => %{"msgtype" => "m.text", "body" => "hello from sync test"},
      "depth" => parent_event.depth + 1,
      "origin_server_ts" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      "prev_events" => [parent_event.event_id],
      "auth_events" => []
    })
    |> Repo.insert!()
  end
end
