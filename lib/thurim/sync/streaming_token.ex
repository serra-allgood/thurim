defmodule Thurim.Sync.StreamingToken do
  @type t :: %{
          pdu_position: integer,
          typing_position: integer,
          receipt_position: integer,
          send_to_device_position: integer,
          invite_position: integer,
          account_data_position: integer,
          device_list_position: integer
        }

  @spec new(String.t() | nil) :: t()
  def new(seed \\ nil)

  def new(seed) when is_nil(seed) do
    %{
      pdu_position: 0,
      typing_position: 0,
      receipt_position: 0,
      send_to_device_position: 0,
      invite_position: 0,
      account_data_position: 0,
      device_list_position: 0
    }
  end

  def new(seed) do
    parts =
      seed
      |> String.split("_")
      |> Enum.map(&String.to_integer/1)

    Enum.zip(
      [
        :pdu_position,
        :typing_position,
        :receipt_position,
        :send_to_device_position,
        :invite_position,
        :account_data_position,
        :device_list_position
      ],
      parts
    )
    |> Map.new()
  end

  @spec is_after?(t(), t()) :: boolean
  def is_after?(first, second) do
    second[:pdu_position] > first[:pdu_position] ||
      second.typing_position > first.typing_position ||
      second.receipt_position > first.receipt_position ||
      second.send_to_device_position > first.send_to_device_position ||
      second.invite_position > first.invite_position ||
      second.account_data_position > first.account_data_position ||
      second.device_list_position > first.device_list_position
  end

  @spec to_string(t()) :: String.t()
  def to_string(token) do
    "#{token.pdu_position}_#{token.typing_position}_#{token.receipt_position}_#{token.send_to_device_position}_#{token.invite_position}_#{token.account_data_position}_#{token.device_list_position}"
  end
end
