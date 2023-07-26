defmodule Thurim.Sync.SyncState.KnockedRoom do
  @derive Jason.Encoder
  defstruct [:knock_state]

  def new() do
    %__MODULE__{knock_state: %{events: []}}
  end
end
