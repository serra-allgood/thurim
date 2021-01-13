defmodule Thurim.EventsTest do
  use Thurim.DataCase

  alias Thurim.Events

  describe "event_state_keys" do
    alias Thurim.Events.EventStateKey

    @valid_attrs %{event_state_key: "some event_state_key"}
    @update_attrs %{event_state_key: "some updated event_state_key"}
    @invalid_attrs %{event_state_key: nil}

    def event_state_key_fixture(attrs \\ %{}) do
      {:ok, event_state_key} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_event_state_key()

      event_state_key
    end

    test "list_event_state_keys/0 returns all event_state_keys" do
      event_state_key = event_state_key_fixture()
      assert Events.list_event_state_keys() == [event_state_key]
    end

    test "get_event_state_key!/1 returns the event_state_key with given id" do
      event_state_key = event_state_key_fixture()
      assert Events.get_event_state_key!(event_state_key.id) == event_state_key
    end

    test "create_event_state_key/1 with valid data creates a event_state_key" do
      assert {:ok, %EventStateKey{} = event_state_key} = Events.create_event_state_key(@valid_attrs)
      assert event_state_key.event_state_key == "some event_state_key"
    end

    test "create_event_state_key/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event_state_key(@invalid_attrs)
    end

    test "update_event_state_key/2 with valid data updates the event_state_key" do
      event_state_key = event_state_key_fixture()
      assert {:ok, %EventStateKey{} = event_state_key} = Events.update_event_state_key(event_state_key, @update_attrs)
      assert event_state_key.event_state_key == "some updated event_state_key"
    end

    test "update_event_state_key/2 with invalid data returns error changeset" do
      event_state_key = event_state_key_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event_state_key(event_state_key, @invalid_attrs)
      assert event_state_key == Events.get_event_state_key!(event_state_key.id)
    end

    test "delete_event_state_key/1 deletes the event_state_key" do
      event_state_key = event_state_key_fixture()
      assert {:ok, %EventStateKey{}} = Events.delete_event_state_key(event_state_key)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event_state_key!(event_state_key.id) end
    end

    test "change_event_state_key/1 returns a event_state_key changeset" do
      event_state_key = event_state_key_fixture()
      assert %Ecto.Changeset{} = Events.change_event_state_key(event_state_key)
    end
  end

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

  describe "event_json" do
    alias Thurim.Events.EventJson

    @valid_attrs %{event_json: %{}}
    @update_attrs %{event_json: %{}}
    @invalid_attrs %{event_json: nil}

    def event_json_fixture(attrs \\ %{}) do
      {:ok, event_json} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Events.create_event_json()

      event_json
    end

    test "list_event_json/0 returns all event_json" do
      event_json = event_json_fixture()
      assert Events.list_event_json() == [event_json]
    end

    test "get_event_json!/1 returns the event_json with given id" do
      event_json = event_json_fixture()
      assert Events.get_event_json!(event_json.id) == event_json
    end

    test "create_event_json/1 with valid data creates a event_json" do
      assert {:ok, %EventJson{} = event_json} = Events.create_event_json(@valid_attrs)
      assert event_json.event_json == %{}
    end

    test "create_event_json/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event_json(@invalid_attrs)
    end

    test "update_event_json/2 with valid data updates the event_json" do
      event_json = event_json_fixture()
      assert {:ok, %EventJson{} = event_json} = Events.update_event_json(event_json, @update_attrs)
      assert event_json.event_json == %{}
    end

    test "update_event_json/2 with invalid data returns error changeset" do
      event_json = event_json_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event_json(event_json, @invalid_attrs)
      assert event_json == Events.get_event_json!(event_json.id)
    end

    test "delete_event_json/1 deletes the event_json" do
      event_json = event_json_fixture()
      assert {:ok, %EventJson{}} = Events.delete_event_json(event_json)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event_json!(event_json.id) end
    end

    test "change_event_json/1 returns a event_json changeset" do
      event_json = event_json_fixture()
      assert %Ecto.Changeset{} = Events.change_event_json(event_json)
    end
  end
end
