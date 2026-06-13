defmodule ThurimCore.Rooms.RoomServer do
  use GenServer
  alias ThurimCore.{Repo, Events}

  # --- Client API ---

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via(room_id))
  end

  def send_event(room_id, event_params) do
    ensure_started(room_id)
    GenServer.call(via(room_id), {:send_event, event_params})
  end

  def get_forward_extremities(room_id) do
    ensure_started(room_id)
    GenServer.call(via(room_id), :get_extremities)
  end

  defp via(room_id) do
    {:via, Registry, {ThurimCore.RoomRegistry, room_id}}
  end

  defp ensure_started(room_id) do
    case Registry.lookup(ThurimCore.RoomRegistry, room_id) do
      [] -> ThurimCore.Rooms.RoomSupervisor.start_room(room_id)
      _ -> :ok
    end
  end

  # --- Server Callbacks ---

  @impl true
  def init(room_id) do
    extremities = []
    # Repo.all(
    #   from e in "room_forward_extremities",
    #     where: e.room_id == ^room_id,
    #     select: e.event_id
    # )

    {:ok, %{room_id: room_id, extremities: MapSet.new(extremities)}}
  end

  # @impl true
  # def handle_call({:send_event, params}, _from, state) do
  #   # 1. Validate auth rules against current state
  #   # 2. Build PDU with prev_events = state.extremities
  #   # 3. Persist atomically via Ecto.Multi
  #   # 4. Update extremities in-memory
  #   # 5. Broadcast via PubSub for /sync subscribers
  #   case persist_event(params, state) do
  #     {:ok, event, new_state} ->
  #       Phoenix.PubSub.broadcast(
  #         ThurimCore.PubSub,
  #         "room:#{state.room_id}",
  #         {:new_event, event}
  #       )

  #       {:reply, {:ok, event}, new_state}

  #     {:error, reason} ->
  #       {:reply, {:error, reason}, state}
  #   end
  # end

  # @impl true
  # def handle_call(:get_extremities, _from, state) do
  #   {:reply, MapSet.to_list(state.extremities), state}
  # end

  # defp persist_event(params, state) do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.insert(:event, build_event(params, state))
  #   |> Ecto.Multi.insert_all(:edges, "event_edges", build_edges(params, state))
  #   |> Ecto.Multi.insert_all(:auth, "event_auth", build_auth(params))
  #   |> maybe_update_state(params)
  #   |> update_extremities(params, state)
  #   |> Repo.transaction()
  #   |> case do
  #     {:ok, %{event: event}} ->
  #       new_extremities =
  #         state.extremities
  #         |> MapSet.difference(MapSet.new(Map.get(params, :prev_events, [])))
  #         |> MapSet.put(event.event_id)

  #       {:ok, event, %{state | extremities: new_extremities}}

  #     {:error, _op, reason, _changes} ->
  #       {:error, reason}
  #   end
  # end

  # defp maybe_update_state(multi, %{state_key: _} = params) do
  #   # For state events: upsert current_state_events and room_memberships
  #   multi
  #   |> Ecto.Multi.run(:state_update, fn repo, %{event: event} ->
  #     repo.insert(
  #       %ThurimCore.Rooms.CurrentStateEvent{
  #         room_id: event.room_id,
  #         type: event.type,
  #         state_key: event.state_key,
  #         event_id: event.event_id
  #       },
  #       on_conflict: {:replace, [:event_id]},
  #       conflict_target: [:room_id, :type, :state_key]
  #     )
  #   end)
  # end

  # defp maybe_update_state(multi, _), do: multi

  # defp update_extremities(multi, params, state) do
  #   prev = Map.get(params, :prev_events, [])

  #   multi
  #   |> Ecto.Multi.run(:extremities, fn repo, %{event: event} ->
  #     # Delete old extremities that are now referenced
  #     repo.delete_all(
  #       from e in "room_forward_extremities",
  #         where: e.room_id == ^state.room_id and e.event_id in ^prev
  #     )

  #     # Insert the new event as a forward extremity
  #     repo.insert_all(
  #       "room_forward_extremities",
  #       [%{room_id: state.room_id, event_id: event.event_id}],
  #       on_conflict: :nothing
  #     )

  #     {:ok, :done}
  #   end)
  # end
end
