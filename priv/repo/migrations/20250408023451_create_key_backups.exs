defmodule Thurim.Repo.Migrations.CreateKeyBackups do
  use Ecto.Migration

  def change do
    create table(:key_backups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :version, :text, null: false
      add :algorithm, :text, null: false
      add :auth_data, :jsonb, null: false
    end
  end
end
