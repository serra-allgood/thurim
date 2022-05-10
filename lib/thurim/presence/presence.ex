defmodule Thurim.Presence do
  alias Thurim.Presence.PresenceAgent

  def set_user_presence(user_id, presence, status_msg \\ nil) do
    agent = PresenceAgent.start_presence_agent(user_id)

    state = %{
      presence: presence,
      status_msg: status_msg,
      last_active: DateTime.utc_now()
    }

    PresenceAgent.put(agent, state)
  end

  def get_user_presence(user_id) do
    with {:ok, agent} <- PresenceAgent.get_presence_agent(user_id) do
      PresenceAgent.get(agent)
    else
      {:error, _} -> :error
    end
  end
end
