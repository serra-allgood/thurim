defmodule Thurim.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :room_id, :text, null: false
      add :room_version, :text, null: false
      add :published, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:rooms, :room_id)
  end
end
