defmodule Thurim.Repo.Migrations.CreateOneTimeKeys do
  use Ecto.Migration

  def change do
    create table(:one_time_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :device_id,
          references(:devices, on_delete: :delete_all, type: :text, column: :device_id),
          null: false

      add :algorithm, :text, null: false
      add :key_id, :text, null: false
      add :key, :text, null: false
      add :signatures, :jsonb, null: false
    end
  end
end
