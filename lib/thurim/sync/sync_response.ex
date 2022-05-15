defmodule Thurim.Sync.SyncResponse do
  alias Thurim.Sync.SyncResponse.InviteRooms
  alias Thurim.Sync.SyncResponse.JoinRooms

  @derive Jason.Encoder
  @enforce_keys [
    :account_data,
    :device_lists,
    :device_one_time_keys_count,
    :next_batch,
    :presence,
    :rooms
  ]
  defstruct [
    :account_data,
    :device_lists,
    :device_one_time_keys_count,
    :next_batch,
    :presence,
    :rooms
  ]

  def new do
    %__MODULE__{
      account_data: [],
      device_lists: [],
      device_one_time_keys_count: 0,
      next_batch: "0",
      presence: [],
      rooms: %{
        invite: InviteRooms.new(),
        join: JoinRooms.new([], []),
        knock: %{},
        leave: %{}
      }
    }
  end
end
