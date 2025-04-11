defmodule Thurim.Repo.Migrations.CreateRoomKeys do
  use Ecto.Migration

  def change do
    create table(:room_keys, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:room_id, :text, null: false)
      add(:sessions, :jsonb, null: false)
      add(:key_backup_id, references(:key_backups, type: :binary_id), null: false)
    end

    create unique_index(:room_keys, [:room_id, :key_backup_id])
    create index(:room_keys, [:room_id])
    create index(:room_keys, [:key_backup_id])
  end
end
