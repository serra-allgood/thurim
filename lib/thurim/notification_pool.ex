defmodule Thurim.NotificationPool do
  use GenServer
  alias Thurim.User
  alias Thurim.UserStream

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = build_state_from_db()
    {:ok, state}
  end

  def build_state_from_db() do
    User.list_accounts()
    |> Enum.reduce(%{}, fn account, pool ->
      Map.put(pool, account.localpart, UserStream.start_link(account.localpart))
    end)
  end
end
