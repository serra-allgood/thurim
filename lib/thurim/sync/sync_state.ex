defmodule Thurim.Sync.SyncState do
  alias Thurim.Sync.SyncState.{
    AccountData,
    Presence,
    Rooms
  }

  @derive Jason.Encoder
  @enforce_keys [:account_data, :next_batch, :presence, :rooms]
  defstruct [
    :account_data,
    # :device_lists,
    # :device_one_time_keys_count,
    :next_batch,
    :presence,
    :rooms
    # :to_device
  ]

  def new(next_batch) when is_integer(next_batch) do
    next_batch
    |> to_string()
    |> new()
  end

  def new(next_batch) when is_binary(next_batch) do
    %__MODULE__{
      account_data: AccountData.new(),
      next_batch: next_batch,
      presence: Presence.new(),
      rooms: Rooms.new()
    }
  end
end
