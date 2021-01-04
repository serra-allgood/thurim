defmodule Thurim.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :session_id, :binary_id, primary_key: true
      add :device_id, :text, null: false
      add :display_name, :text, null: false
      add :last_seen_ts, :naive_datetime
      add :ip, :text
      add :user_agent, :text
      add :localpart, references(:accounts, column: :localpart, on_delete: :delete_all, type: :text)

      timestamps()
    end

    create index(:devices, [:localpart])
    create index(:devices, [:localpart, :device_id])
  end
end
