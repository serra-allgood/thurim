defmodule Thurim.AccountData.AccountDatum do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "account_data" do
    field :content, :map
    field :localpart, :string, primary_key: true
    field :room_id, :string, primary_key: true, default: ""
    field :type, :string, primary_key: true

    timestamps()
  end

  @doc false
  def changeset(account_datum, attrs) do
    account_datum
    |> cast(attrs, [:localpart, :room_id, :type, :content])
    |> validate_required([:localpart, :type, :content])
    |> unique_constraint([:localpart, :room_id, :type], name: :account_data_pkey)
  end
end
