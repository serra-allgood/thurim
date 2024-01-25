defmodule Thurim.Sync.SyncState.AccountData do
  def new() do
    %{events: []}
  end

  def empty?(account_data) do
    Enum.empty?(account_data.events)
  end
end
