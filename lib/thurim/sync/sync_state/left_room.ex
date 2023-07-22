defmodule Thurim.Sync.SyncState.LeftRoom do
  @derive Jason.Encoder
  defstruct [:account_data, :state, :timeline]

  def new() do
    %__MODULE__{
      account_data: [],
      state: [],
      timeline: %{
        events: [],
        limited: false,
        prev_batch: ''
      }
    }
  end
end
