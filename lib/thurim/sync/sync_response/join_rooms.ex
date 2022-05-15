defmodule Thurim.Sync.SyncResponse.JoinRooms do
  @derive Jason.Encoder
  @enforce_keys [
    :account_data,
    :ephemeral,
    :summary,
    :state,
    :timeline,
    :unread_notifications_count
  ]
  defstruct [:account_data, :ephemeral, :summary, :state, :timeline, :unread_notifications_count]

  def new(heroes, state) do
    %__MODULE__{
      account_data: [],
      ephemeral: [],
      state: state,
      summary: %{
        "m.heroes" => heroes,
        "m.invited_member_count" => 0,
        "m.joined_member_count" => 0
      },
      timeline: %{events: [], limited: false, prev_batch: "0"},
      unread_notifications_count: %{highlight_count: 0, notification_count: 0}
    }
  end
end
