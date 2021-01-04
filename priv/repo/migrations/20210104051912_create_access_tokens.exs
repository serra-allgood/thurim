defmodule Thurim.Repo.Migrations.CreateAccessTokens do
  use Ecto.Migration

  def change do
    create table(:access_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_session_id, references(:devices, on_delete: :delete_all, type: :binary_id, column: :session_id)
      add :localpart, references(:accounts, on_delete: :delete_all, type: :text, column: :localpart)

      timestamps()
    end

    create unique_index(:access_tokens, [:device_session_id, :localpart])
    create unique_index(:access_tokens, :device_session_id)
    create index(:access_tokens, :localpart)
  end
end
