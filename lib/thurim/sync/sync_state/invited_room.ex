defmodule Thurim.Sync.SyncState.InvitedRoom do
  @derive Jason.Encoder
  defstruct [:invite_state]

  def new() do
    %__MODULE__{invite_state: %{events: []}}
  end
end
