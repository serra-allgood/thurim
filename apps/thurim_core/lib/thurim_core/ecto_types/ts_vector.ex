defmodule ThurimCore.EctoTypes.TsVector do
  use Ecto.Type
  def type, do: :tsvector

  def cast(v) when is_binary(v), do: {:ok, v}
  def cast(_), do: :error
  def load(v), do: {:ok, v}
  def dump(v) when is_binary(v), do: {:ok, v}
  def dump(_), do: :error
end
