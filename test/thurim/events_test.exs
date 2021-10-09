defmodule Thurim.EventsTest do
  use Thurim.DataCase
  alias Thurim.Events

  describe "state_snapshots" do
    alias Thurim.Events.StateSnapshot

    @valid_attrs %{state_block_ids: []}
    @update_attrs %{state_block_ids: []}
    @invalid_attrs %{state_block_ids: nil}

    def state_snapshot_fixture(attrs \\ %{}) do
      {:ok, state_snapshot} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_state_snapshot()

      state_snapshot
    end

    test "list_state_snapshots/0 returns all state_snapshots" do
      state_snapshot = state_snapshot_fixture()
      assert Events.list_state_snapshots() == [state_snapshot]
    end

    test "get_state_snapshot!/1 returns the state_snapshot with given id" do
      state_snapshot = state_snapshot_fixture()
      assert Events.get_state_snapshot!(state_snapshot.id) == state_snapshot
    end

    test "create_state_snapshot/1 with valid data creates a state_snapshot" do
      assert {:ok, %StateSnapshot{} = state_snapshot} = Events.create_state_snapshot(@valid_attrs)
      assert state_snapshot.state_block_ids == []
    end

    test "create_state_snapshot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_state_snapshot(@invalid_attrs)
    end

    test "update_state_snapshot/2 with valid data updates the state_snapshot" do
      state_snapshot = state_snapshot_fixture()
      assert {:ok, %StateSnapshot{} = state_snapshot} = Events.update_state_snapshot(state_snapshot, @update_attrs)
      assert state_snapshot.state_block_ids == []
    end

    test "update_state_snapshot/2 with invalid data returns error changeset" do
      state_snapshot = state_snapshot_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_state_snapshot(state_snapshot, @invalid_attrs)
      assert state_snapshot == Events.get_state_snapshot!(state_snapshot.id)
    end

    test "delete_state_snapshot/1 deletes the state_snapshot" do
      state_snapshot = state_snapshot_fixture()
      assert {:ok, %StateSnapshot{}} = Events.delete_state_snapshot(state_snapshot)
      assert_raise Ecto.NoResultsError, fn -> Events.get_state_snapshot!(state_snapshot.id) end
    end

    test "change_state_snapshot/1 returns a state_snapshot changeset" do
      state_snapshot = state_snapshot_fixture()
      assert %Ecto.Changeset{} = Events.change_state_snapshot(state_snapshot)
    end
  end

  describe "events" do
    alias Thurim.Events.Event

    @valid_attrs %{auth_event_ids: [], depth: 42, event_id: "some event_id", is_rejected: true, reference_sha256: "some reference_sha256", sent_to_output: true}
    @update_attrs %{auth_event_ids: [], depth: 43, event_id: "some updated event_id", is_rejected: false, reference_sha256: "some updated reference_sha256", sent_to_output: false}
    @invalid_attrs %{auth_event_ids: nil, depth: nil, event_id: nil, is_rejected: nil, reference_sha256: nil, sent_to_output: nil}

    def event_fixture(attrs \\ %{}) do
      {:ok, event} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_event()

      event
    end

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      assert {:ok, %Event{} = event} = Events.create_event(@valid_attrs)
      assert event.auth_event_ids == []
      assert event.depth == 42
      assert event.event_id == "some event_id"
      assert event.is_rejected == true
      assert event.reference_sha256 == "some reference_sha256"
      assert event.sent_to_output == true
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      assert {:ok, %Event{} = event} = Events.update_event(event, @update_attrs)
      assert event.auth_event_ids == []
      assert event.depth == 43
      assert event.event_id == "some updated event_id"
      assert event.is_rejected == false
      assert event.reference_sha256 == "some updated reference_sha256"
      assert event.sent_to_output == false
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end
  end
end
