defmodule Thurim.Sync.SyncResponse.JoinRooms do
  def new do
    %{
      "account_data" => %{"events" => []},
      "ephemeral" => %{"events" => []},
      "state" => %{"events" => []},
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
      "account_data" => %{"events" => attrs[:account_data] || []},
      "ephemeral" => %{"events" => attrs[:ephemeral] || []},
      "state" => %{"events" => attrs[:state] || []},
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
