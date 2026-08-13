defmodule ThurimCore.RoomsTest do
  use ThurimCore.DataCase, async: true

  import Ecto.Query

  alias ThurimCore.{
    Events.CurrentStateEvent,
    Events.Event,
    Events.EventEdge,
    Repo,
    Rooms,
    Rooms.Room
  }

  @creator "@alice:localhost"

  test "creates a private room with its required initial state and event DAG" do
    assert {:ok, %Room{} = room} =
             Rooms.create_room(%{
               "creator" => @creator,
               "sender" => @creator,
               "room_version" => "v12"
             })

    assert room.creator == @creator
    assert room.room_version == "v12"
    refute room.is_public

    events = events_for(room.room_id)

    assert Enum.map(events, & &1.type) == [
             "m.room.create",
             "m.room.member",
             "m.room.power_levels",
             "m.room.join_rules",
             "m.room.history_visibility",
             "m.room.guest_access"
           ]

    assert Enum.map(events, & &1.depth) == Enum.to_list(0..5)
    assert [%Event{content: %{"m.federate" => true, "room_version" => "v12"}} | _] = events
    assert Enum.all?(events, &Map.has_key?(&1.signatures, "localhost"))

    assert EventEdge
           |> where([edge], edge.event_id in ^Enum.map(events, & &1.event_id))
           |> Repo.aggregate(:count) == 5

    assert CurrentStateEvent
           |> where([state], state.room_id == ^room.room_id)
           |> Repo.aggregate(:count) == 6
  end

  test "creates optional room state, canonical alias, and invitations" do
    assert {:ok, %Room{} = room} =
             Rooms.create_room(%{
               "creator" => @creator,
               "sender" => @creator,
               "room_version" => "v12",
               "visibility" => "public",
               "room_alias_name" => "#project:localhost",
               "name" => "Project",
               "topic" => "Project discussion",
               "initial_state" => [
                 %{
                   "type" => "com.example.retention",
                   "state_key" => "",
                   "content" => %{"max_lifetime" => 86_400_000}
                 }
               ],
               "invite" => ["@bob:localhost"]
             })

    assert room.is_public

    events = events_by_type_for(room.room_id)

    assert events["m.room.canonical_alias"].content == %{
             "alias" => "#project:localhost",
             "alt_aliases" => []
           }

    assert events["m.room.join_rules"].content["join_rule"] == "public"
    assert events["m.room.name"].content == %{"name" => "Project"}
    assert events["m.room.topic"].content == %{"topic" => "Project discussion"}
    assert events["com.example.retention"].content == %{"max_lifetime" => 86_400_000}

    assert %Event{state_key: @creator, content: %{"membership" => "join"}} =
             Repo.one!(
               from event in Event,
                 where:
                   event.room_id == ^room.room_id and event.type == "m.room.member" and
                     event.state_key == ^@creator
             )

    assert %Event{state_key: "@bob:localhost", content: %{"membership" => "invite"}} =
             Repo.one!(
               from event in Event,
                 where:
                   event.room_id == ^room.room_id and event.type == "m.room.member" and
                     event.state_key == "@bob:localhost"
             )

    assert CurrentStateEvent
           |> where([state], state.room_id == ^room.room_id)
           |> Repo.aggregate(:count) == 11
  end

  test "rolls back room creation when the room version is unsupported" do
    assert {:error, :room, changeset, %{}} =
             Rooms.create_room(%{
               "creator" => @creator,
               "sender" => @creator,
               "room_version" => "v999"
             })

    assert "is invalid" in errors_on(changeset).room_version
    assert Repo.aggregate(Room, :count) == 0
    assert Repo.aggregate(Event, :count) == 0
  end

  defp events_for(room_id) do
    Repo.all(from event in Event, where: event.room_id == ^room_id, order_by: event.depth)
  end

  defp events_by_type_for(room_id) do
    room_id
    |> events_for()
    |> Map.new(&{&1.type, &1})
  end
end
