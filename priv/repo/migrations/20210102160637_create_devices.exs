defmodule Thurim.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    execute("CREATE SEQUENCE device_version_seq")

    create table(:devices, primary_key: false) do
      add :session_id, :binary_id, primary_key: true
      add :device_id, :text, null: false
      add :display_name, :text, null: false
      add :last_seen_ts, :naive_datetime
      add :ip, :text
      add :user_agent, :text
      add :is_deleted, :boolean, default: false, null: false
      add :mx_user_id, :text, null: false

      add :localpart,
          references(:accounts,
            column: :localpart,
            on_delete: :delete_all,
            type: :text
          ),
          null: false

      timestamps()
    end

    execute(
      "ALTER TABLE devices ADD COLUMN version bigint DEFAULT nextval('device_version_seq') NOT NULL"
    )

    create unique_index(:devices, :device_id)
    create index(:devices, [:localpart])
    create unique_index(:devices, [:localpart, :mx_user_id, :device_id])
  end
end
