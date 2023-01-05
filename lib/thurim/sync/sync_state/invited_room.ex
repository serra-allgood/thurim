defmodule Thurim.Sync.SyncState.InvitedRoom do
  @derive Jason.Encoder
  defstruct [:invite_state]

  def new() do
    %__MODULE__{invite_state: %{events: []}}
  end

  def new(events) when is_list(events) do
    %__MODULE__{invite_state: %{events: events}}
  end
end
