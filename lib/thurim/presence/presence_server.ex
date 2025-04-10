defmodule Thurim.Presence.PresenceServer do
  use GenServer
  alias Thurim.Presence.PresenceState
  alias ThurimWeb.Presence

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{edu_count: 0, listeners: MapSet.new()}}
  end

  def get_device_list_version() do
    GenServer.call(__MODULE__, :get_device_list_version)
  end

  def get_edu_count() do
    GenServer.call(__MODULE__, :get_edu_count)
  end

  def get_user_presence(user_id) do
    GenServer.call(__MODULE__, {:get_user_presence, user_id})
  end

  def register_listener(pid) do
    GenServer.cast(__MODULE__, {:register_listener, pid})
  end

  def set_edu_count(count) do
    GenServer.cast(__MODULE__, {:set_state, :edu_count, count})
    notify_listeners()
  end

  def set_user_presence(user_id, device_id, presence, status_msg) do
    GenServer.cast(__MODULE__, {:set_user_presence, user_id, device_id, presence, status_msg})
    notify_listeners()
  end

  def unregister_listener(pid) do
    GenServer.cast(__MODULE__, {:unregister_listener, pid})
  end

  defp notify_listeners() do
    GenServer.cast(__MODULE__, :notify_listeners)
  end

  @impl true
  def handle_cast(:notify_listeners, state) do
    Enum.each(state.listeners, fn pid -> send(pid, :check_sync) end)
    {:noreply, %{state | listeners: MapSet.new()}}
  end

  @impl true
  def handle_cast({:set_user_presence, user_id, device_id, presence, status_msg}, state) do
    state =
      case Presence.list("presence") |> Map.fetch(user_id) do
        {:ok, _metas} ->
          Presence.update(self(), "presence", user_id, fn meta ->
            put_in(
              meta,
              [:devices, device_id],
              PresenceState.new(%{presence: presence, status_msg: status_msg})
            )
          end)

          %{state | edu_count: state.edu_count + 1}

        :error ->
          Presence.track(
            self(),
            "presence",
            user_id,
            %{
              devices: %{
                device_id =>
                  PresenceState.new(%{
                    presence: presence,
                    status_msg: status_msg
                  })
              }
            }
          )

          %{
            state
            | device_list_version: state.device_list_version + 1,
              edu_count: state.edu_count + 1
          }
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_state, attr, value}, state) do
    {:noreply, %{state | attr => state[attr] + value}}
  end

  @impl true
  def handle_cast({:register_listener, pid}, state) do
    {:noreply, %{state | listeners: MapSet.put(state.listeners, pid)}}
  end

  @impl true
  def handle_cast({:unregister_listener, pid}, state) do
    {:noreply, %{state | listeners: MapSet.delete(state.listeners, pid)}}
  end

  @impl true
  def handle_call(:get_device_list_version, _from, state) do
    {:reply, state.device_list_version, state}
  end

  @impl true
  def handle_call(:get_edu_count, _from, state) do
    {:reply, state.edu_count, state}
  end

  @impl true
  def handle_call({:get_user_presence, user_id}, _from, state) do
    case Presence.list("presence") |> Map.fetch(user_id) do
      {:ok, %{metas: [meta | _]}} ->
        meta.devices
        |> PresenceState.collapse()
        |> PresenceState.to_response()
        |> reply_with(state)

      :error ->
        reply_with(:error, state)
    end
  end

  defp reply_with(reply, state) do
    {:reply, reply, state}
  end
end
