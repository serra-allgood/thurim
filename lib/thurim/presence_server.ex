defmodule Thurim.PresenceServer do
  use GenServer
  alias Thurim.PresenceState
  alias ThurimWeb.Presence

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  def get_user_presence(user_id) do
    GenServer.call(__MODULE__, {:get_user_presence, user_id})
  end

  def set_user_presence(user_id, device_id, presence, status_msg) do
    GenServer.cast(__MODULE__, {:set_user_presence, user_id, device_id, presence, status_msg})
  end

  @impl true
  def handle_cast({:set_user_presence, user_id, device_id, presence, status_msg}, state) do
    case Presence.list("presence") |> Map.fetch(user_id) do
      {:ok, _metas} ->
        Presence.update(self(), "presence", user_id, fn meta ->
          put_in(
            meta,
            [:devices, device_id],
            PresenceState.new(%{presence: presence, status_msg: status_msg})
          )
        end)

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
    end

    {:noreply, state}
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
