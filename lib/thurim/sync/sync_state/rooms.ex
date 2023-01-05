defmodule Thurim.Sync.SyncState.Rooms do
  @derive Jason.Encoder
  @enforce_keys [:invite, :join, :knock, :leave]
  defstruct [:invite, :join, :knock, :leave]

  def new() do
    %__MODULE__{
      invite: %{},
      join: %{},
      knock: %{},
      leave: %{}
    }
  end
end
