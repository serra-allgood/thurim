defmodule Thurim.Repo.Migrations.AddWellKnownEventStateKeys do
  use Ecto.Migration
  alias Thurim.Repo
  alias Thurim.Events.EventStateKey

  def up do
    Repo.insert_all(EventStateKey, [%{id: 1, key: ""}])
  end

  def down do
  end
end
