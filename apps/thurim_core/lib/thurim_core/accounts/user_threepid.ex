defmodule ThurimCore.Accounts.UserThreepid do
  use Ecto.Schema
  import Ecto.Changeset
  alias ThurimCore.EctoTypes.UnixTimestamp

  @primary_key false
  schema "user_threepids" do
    field :medium, :string, primary_key: true
    field :address, :string, primary_key: true
    field :user_id, :string
    field :validated_ts, UnixTimestamp
    field :added_ts, UnixTimestamp
  end

  def changeset(%__MODULE__{} = threepid, attrs) do
    threepid
    |> cast(attrs, [:medium, :address, :user_id, :validated_ts, :added_ts])
    |> validate_required([:medium, :address, :user_id, :added_ts])
    |> validate_inclusion(:medium, ~w(email msisdn))
  end
end
