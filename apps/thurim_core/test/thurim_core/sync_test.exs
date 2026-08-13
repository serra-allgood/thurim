defmodule ThurimCore.SyncTest do
  use ThurimCore.DataCase, async: false

  import Ecto.Query

  alias ThurimCore.{
    Events.Event,
    Repo,
    Rooms,
    Sync,
    Sync.Notifier
  }

  @alice "@alice:localhost"
  @bob "@bob:localhost"

  test "waits on room pubsub notifications and returns updates before timeout" do
    {:ok, room} = create_room_for(@alice)
    {:ok, first_sync} = Sync.sync(@alice)
    since = first_sync["next_batch"]

    task =
      Task.async(fn ->
        started_at = System.monotonic_time(:millisecond)
        {:ok, response} = Sync.sync(@alice, since: since, timeout: 500)
        elapsed = System.monotonic_time(:millisecond) - started_at
        {response, elapsed}
      end)

    Process.sleep(25)
    insert_room_message_event(room.room_id, @alice, "room pubsub wake")
    Notifier.notify_room_update(room.room_id, :timeline_update)

    {response, elapsed_ms} = Task.await(task, 1500)
    timeline_events = response["rooms"]["join"][room.room_id]["timeline"]["events"]

    assert elapsed_ms < 500
    assert Enum.map(timeline_events, & &1["type"]) == ["m.room.message"]
    assert hd(timeline_events)["content"]["body"] == "room pubsub wake"
  end

  test "waits on user pubsub notifications and returns invite updates" do
    task =
      Task.async(fn ->
        started_at = System.monotonic_time(:millisecond)
        {:ok, response} = Sync.sync(@bob, since: "s0", timeout: 600)
        elapsed = System.monotonic_time(:millisecond) - started_at
        {response, elapsed}
      end)

    Process.sleep(25)

    {:ok, room} =
      Rooms.create_room(%{
        "creator" => @alice,
        "sender" => @alice,
        "room_version" => "v12",
        "invite" => [@bob]
      })

    {response, elapsed_ms} = Task.await(task, 1500)

    assert elapsed_ms < 600
    assert Map.has_key?(response["rooms"]["invite"], room.room_id)

    invite_events = response["rooms"]["invite"][room.room_id]["invite_state"]["events"]

    assert Enum.any?(invite_events, fn event ->
             event["type"] == "m.room.member" and event["state_key"] == @bob and
               event["content"]["membership"] == "invite"
           end)
  end

  defp create_room_for(user_id) do
    Rooms.create_room(%{
      "creator" => user_id,
      "sender" => user_id,
      "room_version" => "v12"
    })
  end

  defp insert_room_message_event(room_id, user_id, body) do
    parent_event =
      from(event in Event,
        where: event.room_id == ^room_id,
        order_by: [desc: event.depth],
        limit: 1
      )
      |> Repo.one!()

    Event.changeset(%Event{}, %{
      "event_id" => "$sync-core-test-#{System.unique_integer([:positive])}",
      "room_id" => room_id,
      "sender" => user_id,
      "type" => "m.room.message",
      "content" => %{"msgtype" => "m.text", "body" => body},
      "depth" => parent_event.depth + 1,
      "origin_server_ts" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      "prev_events" => [parent_event.event_id],
      "auth_events" => []
    })
    |> Repo.insert!()
  end
end
