defmodule Thurim.Sync.SyncState do
  alias Thurim.Sync.SyncState.{AccountData, Presence}

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

  def new(next_batch) do
    %__MODULE__{
      account_data: AccountData.new(),
      next_batch: next_batch,
      presence: Presence.new(),
      rooms: %{}
    }
  end
end
