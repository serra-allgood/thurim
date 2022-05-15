defmodule Thurim.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :depth, :bigint, null: false
      add :auth_event_ids, {:array, :string}, null: false

      add :room_id, references(:rooms, on_delete: :nothing, type: :text, column: :room_id),
        null: false

      add :type, :text, null: false

      add :event_id, :text, null: false

      add :state_key,
          references(:event_state_keys, on_delete: :nothing, type: :text, column: :state_key)

      add :content, :map, null: false

      add :sender, :text, null: false

      add :origin_server_ts, :bigint, null: false

      timestamps()
    end

    create index(:events, [:room_id])
    create unique_index(:events, [:event_id])
    create index(:events, [:origin_server_ts])
    create index(:events, [:type, :state_key])
  end
end
