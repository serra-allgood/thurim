defmodule Thurim.Sync.SyncState.JoinedRoom do
  @derive Jason.Encoder
  defstruct [
    :account_data,
    :ephemereal,
    :state,
    :summary,
    :timeline,
    :unread_notifications,
    :unread_thread_notifications
  ]

  def new() do
    %__MODULE__{
      account_data: [],
      ephemereal: [],
      state: [],
      # summary includes the keys m.heroes, m.invited_member_count, and m.joined_member_count,
      # but may omit any of them if they have not changed since the last sync
      summary: %{},
      timeline: %{
        events: [],
        limited: false,
        prev_batch: ''
      },
      unread_notifications: %{
        highlight_count: 0,
        notification_count: 0
      },
      unread_thread_notifications: %{
        highlight_count: 0,
        notification_count: 0
      }
    }
  end
end
