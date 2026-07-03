defmodule ThurimCore.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :event_id, :text, primary_key: true

      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        null: false

      add :sender, :text, null: false
      add :type, :text, null: false
      # NULL => message event; '' or value => state event
      add :state_key, :text
      # jsonb
      add :content, :map, null: false
      add :depth, :bigint, null: false
      add :origin_server_ts, :bigint, null: false
      # DB-assigned monotonic cursor for /sync pagination — never set by application code
      add :stream_ordering, :bigserial
      add :hashes, :map
      add :signatures, :map
      add :unsigned, :map
      # Self-referencing redaction pointer — added after table creation
      add :redacted_by, :text
      add :outlier, :boolean, null: false, default: false
      add :rejected_reason, :text
      add :prev_events, {:array, :text}, null: false, default: []
      add :auth_events, {:array, :text}, null: false, default: []
    end

    alter table(:events) do
      modify :redacted_by,
             references(:events, type: :text, column: :event_id, on_delete: :nilify_all),
             from: :text
    end

    create unique_index(:events, [:stream_ordering])
    create index(:events, [:room_id, :stream_ordering], name: :idx_events_room_stream)
    create index(:events, [:room_id, :depth], name: :idx_events_room_depth)
    create index(:events, [:room_id, :type, :state_key], name: :idx_events_type_state)

    # GIN index for JSONB content queries (e.g. /search, msgtype filtering)
    execute(
      "CREATE INDEX idx_events_content_gin ON events USING gin (content jsonb_path_ops)",
      "DROP INDEX idx_events_content_gin"
    )

    # DAG prev_events edges
    create table(:event_edges, primary_key: false) do
      add :event_id, references(:events, column: :event_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :prev_event_id,
          references(:events, column: :event_id, type: :text, on_delete: :delete_all),
          primary_key: true
    end

    create index(:event_edges, [:prev_event_id], name: :idx_event_edges_prev)

    # auth_events: the state subset used to authorize each event
    create table(:event_auth, primary_key: false) do
      add :event_id, references(:events, column: :event_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :auth_event_id,
          references(:events, column: :event_id, type: :text, on_delete: :delete_all),
          primary_key: true
    end

    create index(:event_auth, :event_id)

    # Forward extremities = current DAG leaves per room
    create table(:room_forward_extremities, primary_key: false) do
      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :event_id, references(:events, column: :event_id, type: :text, on_delete: :delete_all),
        primary_key: true
    end
  end
end
