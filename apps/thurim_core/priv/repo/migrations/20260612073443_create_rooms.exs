defmodule ThurimCore.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      # '!opaque:thurim.example.org'
      add :room_id, :text, primary_key: true
      add :room_version, :text, null: false
      add :creator, :text
      add :is_public, :boolean, null: false, default: false
      add :predecessor_room_id, :text
      add :successor_room_id, :text
      add :created_ts, :utc_datetime_usec, null: false
    end

    create table(:room_aliases, primary_key: false) do
      # '#general:thurim.example.org'
      add :alias, :text, primary_key: true

      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        null: false

      add :creator, :text
      add :is_canonical, :boolean, null: false, default: false
      add :servers, {:array, :text}
    end

    create index(:room_aliases, [:room_id], name: :idx_aliases_room)
  end
end
