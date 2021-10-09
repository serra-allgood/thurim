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

  def get_presence_agent(user_id) do
    with {:error, {:already_started, pid}} <-
           Agent.start_link(
             fn ->
               %{
                 presence: "offline",
                 last_active: DateTime.utc_now()
               }
             end,
             name: via_tuple(user_id)
           ) do
      {:ok, pid}
    else
      {:ok, _} = pid -> pid
    end
  end

  @doc """
  Gets the current presence state
  """
  @spec get(pid) :: t
  def get(pid) do
    Agent.get(pid, fn state ->
      %{presence: state[:presence], status_msg: state[:status_msg], last_active_ago: Timex.diff(Timex.now(), state[:last_active], :milliseconds)}
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

  def via_tuple(user_id),
    do: {:via, Horde.Registry, {Thurim.Registry, "#{__MODULE__}_#{user_id}"}}
end
