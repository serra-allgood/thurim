defmodule Thurim.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "transactions" do
    field :device_id, :string, primary_key: true
    field :localpart, :string, primary_key: true
    field :transaction_id, :string, primary_key: true
    field :event_id, :string

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:localpart, :device_id, :transaction_id, :event_id])
    |> validate_required([:localpart, :device_id, :transaction_id, :event_id])
  end
end
