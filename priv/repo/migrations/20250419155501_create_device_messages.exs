defmodule Thurim.Repo.Migrations.CreateDeviceMessages do
  use Ecto.Migration

  def change do
    execute("CREATE SEQUENCE device_message_seq")

    create table(:device_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :mx_user_id, :text, null: false
      add :device_id, :text, null: false
      add :type, :text, null: false
      add :content, :jsonb, null: false
      add :sender, :text, null: false
    end

    execute(
      "ALTER TABLE device_messages ADD COLUMN count bigint DEFAULT nextval('device_message_seq') NOT NULL"
    )

    create index(:device_messages, [:mx_user_id])
    create index(:device_messages, [:mx_user_id, :device_id])
  end
end
