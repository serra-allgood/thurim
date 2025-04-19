defmodule Thurim.Sync.SyncState do
  alias Thurim.Sync.SyncState.{
    AccountData,
    Presence,
    Rooms
  }

  def new(next_batch) when is_nil(next_batch) do
    new("0_0_0_0")
  end

  def new(next_batch) when is_integer(next_batch) do
    next_batch
    |> to_string()
    |> new()
  end

  def new(next_batch) when is_binary(next_batch) do
    %{
      account_data: AccountData.new(),
      next_batch: next_batch,
      presence: Presence.new(),
      rooms: Rooms.new(),
      to_device: %{events: %{}}
    }
  end

  def empty?(sync_state) do
    Enum.all?(sync_state, fn {key, value} ->
      case key do
        :account_data -> AccountData.empty?(value)
        :presence -> Presence.empty?(value)
        :rooms -> Rooms.empty?(value)
        _ -> true
      end
    end)
  end
end
