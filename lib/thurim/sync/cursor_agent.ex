defmodule Thurim.Sync.CursorAgent do
  use Agent
  alias Thurim.Sync.StreamingToken

  @type t :: %{current_position: StreamingToken.t()}

  def get_agent(localpart, device_id) do
    case Agent.start_link(fn -> StreamingToken.new() end,
           name: key(localpart, device_id) |> via_tuple()
         ) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, _} = tuple -> tuple
    end
  end

  def get_current_position(agent) do
    Agent.get(agent, fn state -> state[:current_position] end)
  end

  def update(agent, position) do
    Agent.update(agent, fn state -> %{state | current_position: position} end)
  end

  defp key(localpart, device_id) do
    "#{__MODULE__}_#{Thurim.User.mx_user_id(localpart)}_#{device_id}"
  end

  defp via_tuple(key) do
    {:via, Horde.Registry, {Thurim.Registry, key}}
  end
end
