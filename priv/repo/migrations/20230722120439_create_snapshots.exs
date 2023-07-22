defmodule Thurim.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, references(:events, column: :event_id, on_delete: :delete_all, type: :text)
      add :sync_token_id, references(:sync_tokens, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create unique_index(:snapshots, [:event_id, :sync_token_id])
    create index(:snapshots, :sync_token_id)
  end
end
