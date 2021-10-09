defmodule Thurim.Repo.Migrations.CreateStateSnapshots do
  use Ecto.Migration

  def change do
    create table(:state_snapshots, primary_key: false) do
      add :id, :bigint, null: false, primary_key: true
      add :state_block_ids, {:array, :bigint}, null: false
      add :room_id, references(:rooms, on_delete: :nothing, column: :room_id, type: :text), null: false

      timestamps()
    end

    create index(:state_snapshots, [:room_id])
  end
end
