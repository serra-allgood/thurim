defmodule Thurim.Sync.Cursor do
  alias Thurim.Events

  defstruct [:event_ts, :device_lists, :invites, :account_data, :receipts, :typing]

  def new() do
    %__MODULE__{
      event_ts: 0,
      device_lists: [],
      invites: [],
      account_data: [],
      receipts: [],
      typing: []
    }
  end

  def update(cursor) do
    %__MODULE__{
      event_ts: Events.find_next_timestamp(cursor.event_ts),
      device_lists: 0,
      invites: 0,
      account_data: 0,
      receipts: 0,
      typing: 0
    }
  end

  def to_token(cursor) do
    "#{cursor.event_ts}_#{cursor.device_lists}_#{cursor.invites}_#{cursor.account_data}_#{cursor.receipts}_#{cursor.typing}"
  end
end
