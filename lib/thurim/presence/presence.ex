defmodule Thurim.Presence do
  alias Thurim.Presence.PresenceAgent

  @spec set_user_presence(String.t(), String.t(), String.t()) :: map
  def set_user_presence(user_id, presence, status_msg \\ nil) do
    with {:ok, agent} <- PresenceAgent.get_presence_agent(user_id) do
      state = %{
        presence: presence,
        status_msg: status_msg,
        last_active: DateTime.utc_now()
      }

      PresenceAgent.put(agent, state)
    end
  end

  def update_user_activity(user_id) do
    with {:ok, agent} <- PresenceAgent.get_presence_agent(user_id) do
      state = %{
        last_active: DateTime.utc_now()
      }

      PresenceAgent.put(agent, state)
    end
  end

  @spec get_user_presence(Strint.t()) :: map
  def get_user_presence(user_id) do
    with {:ok, agent} <- PresenceAgent.get_presence_agent(user_id) do
      PresenceAgent.get(agent)
    end
  end
end
