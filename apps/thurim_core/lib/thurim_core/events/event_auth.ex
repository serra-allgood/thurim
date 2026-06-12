defmodule MatrixCore.Events.EventAuth do
  use Ecto.Schema
  @primary_key false
  schema "event_auth" do
    field :event_id, :string, primary_key: true
    field :auth_event_id, :string, primary_key: true
  end
end
