defmodule Thurim.Repo.Migrations.CreateSyncTokens do
  use Ecto.Migration

  def change do
    create table(:sync_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :device_session_id,
          references(:devices,
            column: :session_id,
            on_delete: :delete_all,
            type: :binary_id
          ),
          null: false

      timestamps()
    end

    create index(:sync_tokens, :device_session_id)
  end
end
