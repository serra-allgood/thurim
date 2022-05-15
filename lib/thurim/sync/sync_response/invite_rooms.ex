defmodule Thurim.Sync.SyncResponse.InviteRooms do
  @derive Jason.Encoder
  @enforce_keys [:events]
  defstruct [:events]

  def new do
    %__MODULE__{events: []}
  end
end
