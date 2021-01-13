defmodule Thurim.RoomsTest do
  use Thurim.DataCase

  alias Thurim.Rooms

  describe "rooms" do
    alias Thurim.Rooms.Room

    @valid_attrs %{last_event_sent_nid: 42, latest_event_nids: [], room_id: "some room_id", room_version: "some room_version"}
    @update_attrs %{last_event_sent_nid: 43, latest_event_nids: [], room_id: "some updated room_id", room_version: "some updated room_version"}
    @invalid_attrs %{last_event_sent_nid: nil, latest_event_nids: nil, room_id: nil, room_version: nil}

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rooms.create_room()

      room
    end

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Rooms.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Rooms.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      assert {:ok, %Room{} = room} = Rooms.create_room(@valid_attrs)
      assert room.last_event_sent_nid == 42
      assert room.latest_event_nids == []
      assert room.room_id == "some room_id"
      assert room.room_version == "some room_version"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      assert {:ok, %Room{} = room} = Rooms.update_room(room, @update_attrs)
      assert room.last_event_sent_nid == 43
      assert room.latest_event_nids == []
      assert room.room_id == "some updated room_id"
      assert room.room_version == "some updated room_version"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room(room, @invalid_attrs)
      assert room == Rooms.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Rooms.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room(room)
    end
  end

  describe "room_aliases" do
    alias Thurim.Rooms.RoomAlias

    @valid_attrs %{alias: "some alias", create_id: "some create_id", room_id: "some room_id"}
    @update_attrs %{alias: "some updated alias", create_id: "some updated create_id", room_id: "some updated room_id"}
    @invalid_attrs %{alias: nil, create_id: nil, room_id: nil}

    def room_alias_fixture(attrs \\ %{}) do
      {:ok, room_alias} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rooms.create_room_alias()

      room_alias
    end

    test "list_room_aliases/0 returns all room_aliases" do
      room_alias = room_alias_fixture()
      assert Rooms.list_room_aliases() == [room_alias]
    end

    test "get_room_alias!/1 returns the room_alias with given id" do
      room_alias = room_alias_fixture()
      assert Rooms.get_room_alias!(room_alias.id) == room_alias
    end

    test "create_room_alias/1 with valid data creates a room_alias" do
      assert {:ok, %RoomAlias{} = room_alias} = Rooms.create_room_alias(@valid_attrs)
      assert room_alias.alias == "some alias"
      assert room_alias.create_id == "some create_id"
      assert room_alias.room_id == "some room_id"
    end

    test "create_room_alias/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room_alias(@invalid_attrs)
    end

    test "update_room_alias/2 with valid data updates the room_alias" do
      room_alias = room_alias_fixture()
      assert {:ok, %RoomAlias{} = room_alias} = Rooms.update_room_alias(room_alias, @update_attrs)
      assert room_alias.alias == "some updated alias"
      assert room_alias.create_id == "some updated create_id"
      assert room_alias.room_id == "some updated room_id"
    end

    test "update_room_alias/2 with invalid data returns error changeset" do
      room_alias = room_alias_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room_alias(room_alias, @invalid_attrs)
      assert room_alias == Rooms.get_room_alias!(room_alias.id)
    end

    test "delete_room_alias/1 deletes the room_alias" do
      room_alias = room_alias_fixture()
      assert {:ok, %RoomAlias{}} = Rooms.delete_room_alias(room_alias)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room_alias!(room_alias.id) end
    end

    test "change_room_alias/1 returns a room_alias changeset" do
      room_alias = room_alias_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room_alias(room_alias)
    end
  end
end
