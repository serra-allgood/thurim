defmodule ThurimCore.Rooms.RoomServer.State do
  defstruct [
    :room_id,
    # governs auth & state-res algorithm
    :room_version,
    # set of event_ids at the DAG frontier
    forward_extremities: MapSet.new(),
    # %{{type, state_key} => Event.t} projection
    current_state: %{},
    # event_id → [auth_event_id] for quick lookup
    auth_chain_cache: %{},
    idle_timer: nil
  ]
end
