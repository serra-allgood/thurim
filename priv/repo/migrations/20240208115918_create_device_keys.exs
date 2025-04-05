defmodule Thurim.Repo.Migrations.CreateDeviceKeys do
  use Ecto.Migration

  def change do
    create table(:device_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :device_id,
          references(:devices, on_delete: :delete_all, type: :text, column: :device_id),
          null: false

      add :algorithm, :text, null: false
      add :type, :text, null: false
      add :key, :text, null: false
      add :signatures, :jsonb

      timestamps()
    end
  end
end
