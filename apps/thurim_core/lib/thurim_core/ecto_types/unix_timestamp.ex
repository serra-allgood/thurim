defmodule ThurimCore.EctoTypes.UnixTimestamp do
  use Ecto.Type
  def type, do: :bigint

  def cast(%DateTime{} = v), do: {:ok, DateTime.to_unix(v, :millisecond)}
  # def cast(v) when is_integer(v), do: {:ok, v}
  def cast(_), do: :error
  def load(v), do: DateTime.from_unix(v, :millisecond)
  def dump(%DateTime{} = v), do: {:ok, DateTime.to_unix(v, :millisecond)}
  def dump(v) when is_integer(v), do: {:ok, v}
  def dump(_), do: :error
end
