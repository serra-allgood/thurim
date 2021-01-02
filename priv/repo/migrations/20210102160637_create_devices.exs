defmodule Thurim.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :access_token, :text, null: false
      add :device_id, :text, null: false
      add :display_name, :text, null: false
      add :last_seen_ts, :naive_datetime
      add :ip, :text
      add :user_agent, :text
      add :account_id, references(:accounts, column: :localpart, on_delete: :delete_all, type: :text)

      timestamps()
    end

    create unique_index(:devices, [:access_token])
    create index(:devices, [:account_id])
    create index(:devices, [:account_id, :device_id])
  end
end
