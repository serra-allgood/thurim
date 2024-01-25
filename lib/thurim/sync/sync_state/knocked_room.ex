defmodule Thurim.Sync.SyncState.KnockedRoom do
  def new() do
    %{knock_state: %{events: []}}
  end
end
