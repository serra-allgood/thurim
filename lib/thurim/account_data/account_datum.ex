defmodule Thurim.AccountData.AccountDatum do
  use Ecto.Schema
  import Ecto.Changeset

  schema "account_data" do
    field :content, :string
    field :localpart, :string, primary_key: true
    field :room_id, :string, primary_key: true, default: ""
    field :type, :string, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(account_datum, attrs) do
    account_datum
    |> cast(attrs, [:localpart, :room_id, :type, :content])
    |> validate_required([:localpart, :room_id, :type, :content])
  end
end
