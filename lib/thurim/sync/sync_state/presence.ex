defmodule Thurim.Sync.SyncState.Presence do
  @derive Jason.Encoder
  defstruct [:events]

  def new() do
    %__MODULE__{events: []}
  end
end
