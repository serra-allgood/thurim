defmodule ThurimCore.Keys.SigningKeyStore do
  use GenServer
  import ThurimCore.Utils, only: [then_if: 3]
  alias ThurimCore.{Keys, Keys.ServerSigningKey}

  def start_link(_options) do
    GenServer.start_link(__MODULE__, %{active: nil, published: []}, name: __MODULE__)
  end

  def active_key, do: GenServer.call(__MODULE__, :active)
  def published_keys, do: GenServer.call(__MODULE__, :published)
  def retire_active_key, do: GenServer.cast(__MODULE__, :retire)

  defp schedule_retirement(%ServerSigningKey{} = key) do
    retire_delay =
      DateTime.diff(key.valid_until_ts, DateTime.utc_now(:millisecond), :millisecond)

    Process.send_after(self(), :retire, retire_delay)
  end

  @impl true
  def init(_) do
    active =
      Keys.get_active_server_signing_key()
      |> then_if(&is_nil(&1), fn _arg ->
        {:ok, key} = Keys.retire_signing_key()
        key
      end)

    published = Keys.all_server_signing_keys()

    schedule_retirement(active)

    {:ok, %{active: active, published: published}}
  end

  @impl true
  def handle_call(:active, _from, state) do
    {:reply, state.active, state}
  end

  @impl true
  def handle_call(:published, _from, state) do
    {:reply, state.published, state}
  end

  @impl true
  def handle_info(:retire, state) do
    {:ok, key} = Keys.retire_signing_key()

    schedule_retirement(key)

    {:noreply, %{state | active: key}}
  end
end
