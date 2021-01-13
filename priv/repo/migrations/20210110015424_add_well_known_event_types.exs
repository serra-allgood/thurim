defmodule Thurim.Repo.Migrations.AddWellKnownEventTypes do
  use Ecto.Migration
  alias Thurim.Repo
  alias Thurim.EventTypes.EventType

  def up do
    Repo.insert_all(EventType, [
      %{id: 1, name: "m.room.create"},
      %{id: 2, name: "m.room.power_levels"},
      %{id: 3, name: "m.room.join_rules"},
      %{id: 4, name: "m.room.third_party_invite"},
      %{id: 5, name: "m.room.member"},
      %{id: 6, name: "m.room.redaction"},
      %{id: 7, name: "m.room.history_visibility"}
    ])
  end

  def down do
  end
end
