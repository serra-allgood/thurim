defmodule Thurim.Sync.SyncState.InvitedRoom do
  def new() do
    %{invite_state: %{events: []}}
  end

  def new(events) when is_list(events) do
    %{invite_state: %{events: events}}
  end

  def empty?({_room_id, response}) do
    Enum.empty?(response.invite_state.events)
  end
end
