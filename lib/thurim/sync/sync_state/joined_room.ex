defmodule Thurim.Sync.SyncState.JoinedRoom do
  alias Thurim.Events

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

  def new(room_id, mx_user_id, since \\ nil)

  def new(room_id, mx_user_id, since) when is_nil(since) do
    new()
    |> update_in(:summary, fn summary ->
      heroes = Events.heroes_for_room_id(room_id, mx_user_id)
      invited_member_count = Events.invited_member_count(room_id)
      joined_member_count = Events.joined_member_count(room_id)

      put_in(summary, "m.heroes", heroes)
      |> put_in("m.invited_member_count", invited_member_count)
      |> put_in("m.joined_member_count", joined_member_count)
    end)
    |> update_in(:state, fn state ->
      nil
    end)
  end
end
