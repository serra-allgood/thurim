defmodule Thurim.Sync.SyncResponse.JoinRooms do
  def new(heroes, state, timeline) do
    %{
      "account_data" => [],
      "ephemeral" => [],
      "state" => state,
      "summary" => %{
        "m.heroes" => heroes,
        "m.invited_member_count" => 0,
        "m.joined_member_count" => 0
      },
      "timeline" => %{"events" => timeline, "limited" => false, "prev_batch" => "0"},
      "unread_notifications_count" => %{"highlight_count" => 0, "notification_count" => 0}
    }
  end
end
