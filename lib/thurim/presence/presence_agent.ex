defmodule Thurim.Presence.PresenceAgent do
  use Agent
  require Logger

  @type t :: %{
          presence: String.t(),
          last_active: DateTime.t(),
          status_msg: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:presence]
  defstruct [:presence, :status_msg, :last_active_ago]

  @spec start_presence_agent(String.t()) :: pid
  def start_presence_agent(user_id) do
    case Agent.start_link(
           fn -> %{presence: "offline", last_active: Timex.now("UTC")} end,
           name: via_tuple(user_id)
         ) do
      {:error, {:already_started, pid}} -> pid
      {:ok, pid} -> pid
    end
  end

  def get_presence_agent(user_id) do
    case Horde.Registry.lookup(Thurim.Registry, key(user_id)) do
      [{pid, _} | _] ->
        {:ok, pid}

      _ ->
        {:error, "not found"}
    end
  end

  @doc """
  Gets the current presence state
  """
  @spec get(pid) :: t
  def get(pid) do
    Agent.get(pid, fn state ->
      %{
        presence: state[:presence],
        status_msg: state[:status_msg],
        last_active_ago: Timex.diff(Timex.now("UTC"), state[:last_active], :milliseconds)
      }
    end)
  end

  @doc """
  Updates the current presence state
  """
  @spec put(pid, map) :: :ok
  def put(pid, state) do
    Enum.each(state, fn {key, value} ->
      Agent.update(pid, &Map.put(&1, key, value))
    end)
  end

  defp via_tuple(user_id),
    do: {:via, Horde.Registry, {Thurim.Registry, key(user_id)}}

  defp key(user_id), do: "#{__MODULE__}_#{user_id}"
end
