defmodule Thurim.Sync.SyncResponse.JoinRooms do
  def new do
    %{
      "account_data" => [],
      "ephemeral" => [],
      "state" => [],
      "summary" => %{
        "m.heroes" => [],
        "m.invited_member_count" => 0,
        "m.joined_member_count" => 0
      },
      "timeline" => %{"events" => [], "limited" => false, "prev_batch" => "0"},
      "unread_notifications_count" => %{"highlight_count" => 0, "notification_count" => 0}
    }
  end

  def new(attrs) do
    %{
      "account_data" => attrs[:account_data] || [],
      "ephemeral" => attrs[:ephemeral] || [],
      "state" => attrs[:state] || [],
      "summary" => %{
        "m.heroes" => attrs[:heroes] || [],
        "m.invited_member_count" => attrs[:invited_member_count] || 0,
        "m.joined_member_count" => attrs[:joined_member_count] || 0
      },
      "timeline" => %{
        "events" => attrs[:timeline] || [],
        "limited" => false,
        "prev_batch" => attrs[:prev_batch] || "0"
      },
      "unread_notifications_count" => %{"highlight_count" => 0, "notification_count" => 0}
    }
  end
end
