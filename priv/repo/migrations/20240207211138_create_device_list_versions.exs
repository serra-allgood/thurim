defmodule Thurim.Repo.Migrations.CreateDeviceListVersions do
  use Ecto.Migration

  def change do
    create table(:device_list_versions, primary_key: false) do
      add :user_id, :text, primary_key: true
      add :version, :bigint, null: false
    end
  end
end
