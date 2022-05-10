defmodule Thurim.Sync.Cursor do
  defstruct [:event_ts, :device_lists, :invites, :account_data]

  def new() do
    %__MODULE__{}
  end

  def update(cursor, account, device) do
  end
end
