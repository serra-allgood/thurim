defmodule Thurim.PresenceState do
  @enforce_keys [:presence, :status_msg, :last_active]
  defstruct [:presence, :status_msg, :last_active]

  def new(%{presence: presence, status_msg: status_msg, last_active: last_active}) do
    %__MODULE__{presence: presence, status_msg: status_msg, last_active: last_active}
  end

  def new(%{presence: presence, status_msg: status_msg}) do
    %__MODULE__{presence: presence, status_msg: status_msg, last_active: DateTime.utc_now()}
  end

  def collapse(device_states) do
    Map.values(device_states)
    |> Enum.max_by(fn state -> state.last_active end)
    |> new()
  end

  def to_response(%__MODULE__{} = state) do
    %{
      presence: state.presence,
      status_msg: state.status_msg,
      last_active_ago: Timex.diff(Timex.now("UTC"), state.last_active, :milliseconds)
    }
  end
end
