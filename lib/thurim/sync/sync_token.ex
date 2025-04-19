defmodule Thurim.Sync.SyncToken do
  import Ecto.Query, warn: false
  import Thurim.Events, only: [max_pdu_count: 0]
  import Thurim.Devices, only: [max_device_version: 0]
  import Thurim.DeviceMessages, only: [max_device_message_count: 2]
  alias Thurim.Presence.PresenceServer

  def current_edu_count() do
    PresenceServer.get_edu_count()
  end

  def current_sync_token(mx_user_id, device_id, []) do
    "#{max_pdu_count()}_#{max_device_message_count(mx_user_id, device_id)}_#{max_device_version()}_#{current_edu_count()}"
  end

  def current_sync_token(mx_user_id, device_id, tokens) do
    [_pdu_count, _max_device_message_count, _device_list_version, edu_count] = tokens

    if edu_count > current_edu_count() do
      PresenceServer.set_edu_count(edu_count)
    end

    "#{max_pdu_count()}_#{max_device_message_count(mx_user_id, device_id)}_#{max_device_version()}_#{current_edu_count()}"
  end

  def extract_pdu_token(token) do
    String.split(token, "_")
    |> Enum.map(&String.to_integer/1)
    |> List.first()
  end
end
