defmodule ThurimCore.EctoTypes.Inet do
  use Ecto.Type
  def type, do: :inet

  def cast(%Postgrex.INET{} = v), do: {:ok, v}

  def cast(str) when is_binary(str) do
    case :inet.parse_address(String.to_charlist(str)) do
      {:ok, addr} -> {:ok, %Postgrex.INET{address: addr}}
      _ -> :error
    end
  end

  def cast(_), do: :error

  def load(%Postgrex.INET{} = v), do: {:ok, v}
  def load(_), do: :error

  def dump(%Postgrex.INET{} = v), do: {:ok, v}
  def dump(_), do: :error
end
