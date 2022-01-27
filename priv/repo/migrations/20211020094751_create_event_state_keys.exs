defmodule Thurim.Repo.Migrations.CreateEventStateKeys do
  use Ecto.Migration

  def change do
    create table(:event_state_keys, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :state_key, :text, null: false
    end

    create index(:event_state_keys, :state_key, unique: true)
  end
end
