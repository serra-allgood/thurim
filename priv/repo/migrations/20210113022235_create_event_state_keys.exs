defmodule Thurim.Repo.Migrations.CreateEventStateKeys do
  use Ecto.Migration

  def change do
    execute "CREATE SEQUENCE IF NOT EXISTS event_state_key_id_seq START 65536",
            "DROP SEQUENCE IF EXISTS event_state_key_id_seq"

    flush()

    create table(:event_state_keys, primary_key: false) do
      add :id, :bigint,
        primary_key: true,
        null: false,
        default: fragment("nextval('event_state_key_id_seq'::regclass)")

      add :key, :text, null: false
    end

    create unique_index(:event_state_keys, :key)
  end
end
