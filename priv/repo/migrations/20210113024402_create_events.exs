defmodule Thurim.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :sent_to_output, :boolean, default: false, null: false
      add :depth, :bigint, null: false
      add :event_id, :text, null: false
      add :reference_sha256, :binary, null: false
      add :auth_event_ids, {:array, :bigint}, null: false
      add :is_rejected, :boolean, default: false, null: false
      add :room_id, references(:rooms, on_delete: :nothing, type: :text, column: :room_id), null: false
      add :type, :text, null: false
      add :state_key, :text
      add :content, :map, null: false
      add :state_snapshot_id, references(:state_snapshots, on_delete: :nothing, type: :bigint), default: 0

      timestamps()
    end

    create index(:events, [:room_id])
    create index(:events, [:state_snapshot_id])
    create unique_index(:events, [:event_id])
  end
end
