defmodule ThurimCore.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :device_id, :text, primary_key: true
      add :display_name, :text
      add :last_seen_ts, :bigint
      add :last_seen_ip, :inet
    end
  end
end
