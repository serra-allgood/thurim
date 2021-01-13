defmodule Thurim.Repo.Migrations.CreateEventTypes do
  use Ecto.Migration

  def change do
    execute "CREATE SEQUENCE IF NOT EXISTS event_types_id_seq START 65536", "DROP SEQUENCE IF EXISTS event_types_id_seq"

    flush()

    create table(:event_types, primary_key: false) do
      add :id, :bigint, primary_key: true, default: fragment("nextval('event_types_id_seq'::regclass)")
      add :name, :text, null: false
    end

    create unique_index(:event_types, :name)
  end
end
