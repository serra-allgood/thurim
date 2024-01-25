defmodule Thurim.Sync.SyncState.Presence do
  def new() do
    %{events: []}
  end

  def empty?(presence) do
    Enum.empty?(presence.events)
  end
end
