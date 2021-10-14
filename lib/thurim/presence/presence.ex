defmodule Thurim.Presence do
  alias Thurim.Presence.PresenceAgent

  @spec set_user_presence(String.t(), String.t(), String.t() | nil) :: :ok
  def set_user_presence(user_id, presence, status_msg \\ nil) do
    agent = PresenceAgent.start_presence_agent(user_id)
    state = %{
      presence: presence,
      status_msg: status_msg,
      last_active: DateTime.utc_now()
    }

    PresenceAgent.put(agent, state)
  end

  def update_user_activity(user_id) do
    with {:ok, agent} <- PresenceAgent.start_presence_agent(user_id) do
      state = %{
        last_active: DateTime.utc_now()
      }

      PresenceAgent.put(agent, state)
    end
  end

  @spec get_user_presence(Strint.t()) :: map | atom()
  def get_user_presence(user_id) do
    with {:ok, agent} <- PresenceAgent.get_presence_agent(user_id) do
      PresenceAgent.get(agent)
    else
      {:error, _} -> :error
    end
  end
end
