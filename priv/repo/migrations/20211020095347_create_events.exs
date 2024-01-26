defmodule Thurim.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    execute("CREATE SEQUENCE stream_ordering_seq")

    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :depth, :bigint, null: false
      add :auth_events, {:array, :string}, null: false
      add :room_id, references(:rooms, on_delete: :nothing, type: :text, column: :room_id),
        null: false
      add :type, :text, null: false
      add :event_id, :text, null: false
      add :state_key,
          references(:event_state_keys, on_delete: :nothing, type: :text, column: :state_key)
      add :content, :map, null: false
      add :sender, :text, null: false
      add :origin_server_ts, :bigint, null: false
      add :origin, :text, null: false
      add :redacts, :text
      add :pdu_count, :bigint, null: false

      timestamps()
    end

    execute(
      "ALTER TABLE events ADD COLUMN stream_ordering bigint DEFAULT nextval('stream_ordering_seq')"
    )

    create index(:events, [:room_id])
    create unique_index(:events, [:event_id])
    create index(:events, [:origin_server_ts])
    create index(:events, [:type, :state_key])
  end
end
