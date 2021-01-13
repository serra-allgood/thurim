defmodule Thurim.EventTypesTest do
  use Thurim.DataCase

  alias Thurim.EventTypes

  describe "event_types" do
    alias Thurim.EventTypes.EventType

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def event_type_fixture(attrs \\ %{}) do
      {:ok, event_type} =
        attrs
        |> Enum.into(@valid_attrs)
        |> EventTypes.create_event_type()

      event_type
    end

    test "list_event_types/0 returns all event_types" do
      event_type = event_type_fixture()
      assert EventTypes.list_event_types() == [event_type]
    end

    test "get_event_type!/1 returns the event_type with given id" do
      event_type = event_type_fixture()
      assert EventTypes.get_event_type!(event_type.id) == event_type
    end

    test "create_event_type/1 with valid data creates a event_type" do
      assert {:ok, %EventType{} = event_type} = EventTypes.create_event_type(@valid_attrs)
      assert event_type.name == "some name"
    end

    test "create_event_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = EventTypes.create_event_type(@invalid_attrs)
    end

    test "update_event_type/2 with valid data updates the event_type" do
      event_type = event_type_fixture()
      assert {:ok, %EventType{} = event_type} = EventTypes.update_event_type(event_type, @update_attrs)
      assert event_type.name == "some updated name"
    end

    test "update_event_type/2 with invalid data returns error changeset" do
      event_type = event_type_fixture()
      assert {:error, %Ecto.Changeset{}} = EventTypes.update_event_type(event_type, @invalid_attrs)
      assert event_type == EventTypes.get_event_type!(event_type.id)
    end

    test "delete_event_type/1 deletes the event_type" do
      event_type = event_type_fixture()
      assert {:ok, %EventType{}} = EventTypes.delete_event_type(event_type)
      assert_raise Ecto.NoResultsError, fn -> EventTypes.get_event_type!(event_type.id) end
    end

    test "change_event_type/1 returns a event_type changeset" do
      event_type = event_type_fixture()
      assert %Ecto.Changeset{} = EventTypes.change_event_type(event_type)
    end
  end
end
