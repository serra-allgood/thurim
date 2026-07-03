defmodule ThurimCore.Events.EventAuth do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "event_auth" do
    field :event_id, :string, primary_key: true
    field :auth_event_id, :string, primary_key: true
  end

  def changeset(%__MODULE__{} = event_auth, attrs) do
    event_auth
    |> cast(attrs, [:event_id, :auth_event_id])
    |> validate_required([:event_id, :auth_event_id])
  end
end
