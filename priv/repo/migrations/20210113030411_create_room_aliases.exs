defmodule Thurim.Repo.Migrations.CreateRoomAliases do
  use Ecto.Migration

  def change do
    create table(:room_aliases, primary_key: false) do
      add :alias, :text, primary_key: true, null: false

      add :room_id, references(:rooms, on_delete: :nothing, type: :text, column: :room_id),
        null: false

      add :creator_id, :text, null: false

      timestamps()
    end

    create index(:room_aliases, [:room_id])
  end
end
