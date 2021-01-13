defmodule Thurim.Repo.Migrations.CreateEventJson do
  use Ecto.Migration

  def change do
    create table(:event_json, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_json, :map, null: false
      add :event_id, references(:events, on_delete: :nothing, type: :bigint), null: false
    end

    create index(:event_json, [:event_id])
  end
end
