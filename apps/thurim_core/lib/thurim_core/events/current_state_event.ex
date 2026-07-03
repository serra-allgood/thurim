defmodule ThurimCore.Events.CurrentStateEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "current_state_events" do
    field :room_id, :string, primary_key: true
    field :type, :string, primary_key: true
    field :state_key, :string, primary_key: true
    field :event_id, :string
  end

  @fields ~w(room_id type state_key event_id)a

  def changeset(%__MODULE__{} = event, attrs) do
    event
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
