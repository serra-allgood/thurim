defmodule Thurim.Sync.SyncToken do
  import Ecto.Query, warn: false
  import Thurim.Events, only: [max_pdu_count: 0]
  import Thurim.Devices, only: [max_device_version: 0]
  alias Thurim.Presence.PresenceServer

  def current_edu_count() do
    PresenceServer.get_edu_count()
  end

  def current_sync_token([]) do
    "#{max_pdu_count()}_#{max_device_version()}_#{current_edu_count()}"
  end

  def current_sync_token(tokens) do
    [_pdu_count, _device_list_version, edu_count] = tokens

    if edu_count > current_edu_count() do
      PresenceServer.set_edu_count(edu_count)
    end

    "#{max_pdu_count()}_#{max_device_version()}_#{current_edu_count()}"
  end
end
