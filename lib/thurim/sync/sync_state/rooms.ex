defmodule Thurim.Sync.SyncState.Rooms do
  def new() do
    %{
      invite: %{},
      join: %{},
      knock: %{},
      leave: %{}
    }
  end

  def empty?(rooms) do
    Enum.all?(rooms, fn {_key, value} -> Enum.empty?(value) end)
  end
end
