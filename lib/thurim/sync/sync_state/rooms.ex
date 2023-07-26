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

  def empty?(rooms) do
    Enum.all?(rooms, fn {_key, value} -> Enum.empty?(value) end)
  end
end
