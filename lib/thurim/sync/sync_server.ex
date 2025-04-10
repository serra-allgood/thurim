defmodule Thurim.Sync.SyncServer do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{listeners: MapSet.new()}}
  end

  def register_listener(pid) do
    GenServer.cast(__MODULE__, {:register_listener, pid})
  end

  def notify_listeners() do
    GenServer.cast(__MODULE__, :notify_listeners)
  end

  def unregister_listener(pid) do
    GenServer.cast(__MODULE__, {:unregister_listener, pid})
  end

  @impl true
  def handle_cast({:register_listener, pid}, state) do
    {:noreply, %{state | listeners: MapSet.put(state.listeners, pid)}}
  end

  @impl true
  def handle_cast(:notify_listeners, state) do
    state.listeners
    |> Enum.each(fn listener -> send(listener, :check_sync) end)

    {:noreply, %{state | listeners: MapSet.new()}}
  end

  @impl true
  def handle_cast({:unregister_listener, pid}, state) do
    {:noreply, %{state | listeners: MapSet.delete(state.listeners, pid)}}
  end
end
