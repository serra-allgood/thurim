defmodule Thurim.Repo.Migrations.CreateKeyBackups do
  use Ecto.Migration

  def change do
    create table(:key_backups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :version, :text, null: false
      add :algorithm, :text, null: false
      add :auth_data, :jsonb, null: false
      add :etag, :text, null: false

      add :localpart,
          references(:accounts,
            column: :localpart,
            on_delete: :delete_all,
            type: :text
          ),
          null: false

      timestamps()
    end

    create index(:key_backups, [:localpart, :version])
  end
end
