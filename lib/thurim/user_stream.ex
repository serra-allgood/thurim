defmodule Thurim.UserStream do
  use GenServer
  alias Thurim.Devices
  alias Thurim.PresencePool

  def start_link(account_localpart) do
    GenServer.start_link(__MODULE__, account_localpart, name: __MODULE__)
  end

  def init(account_localpart) do
    state = build_state(account_localpart)
    {:ok, state}
  end

  def build_state(account_localpart) do
    %{}
    |> Map.put("presence_pool", PresencePool.start_link(Devices.list_devices(account_localpart)))
    |> Map.put("sync_pointer", "")
  end
end
