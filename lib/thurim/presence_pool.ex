defmodule Thurim.PresencePool do
  use GenServer
  alias Thurim.Presence.PresenceAgent

  def start_link(devices) do
    GenServer.start_link(__MODULE__, devices, name: __MODULE__)
  end

  def init(devices) do
    state = build_state(devices)
    {:ok, state}
  end

  def build_state(devices) do
    Enum.reduce(devices, %{}, fn device, pool ->
      Map.put(pool, device.session_id, PresenceAgent.start_presence_agent(device.session_id))
    end)
  end
end
