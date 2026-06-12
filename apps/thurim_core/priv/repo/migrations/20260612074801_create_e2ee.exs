defmodule ThurimCore.Repo.Migrations.CreateE2ee do
  use Ecto.Migration

  def change do
    # Per-device identity & signing keys (uploaded via /keys/upload)
    create table(:device_keys, primary_key: false) do
      add :user_id, :text, primary_key: true
      add :device_id, :text, primary_key: true
      # algorithms, keys, signatures
      add :key_json, :map, null: false
      add :stream_id, :bigserial
    end

    execute(
      """
      ALTER TABLE device_keys
        ADD CONSTRAINT device_keys_device_fk
        FOREIGN KEY (user_id, device_id)
        REFERENCES devices (user_id, device_id)
        ON DELETE CASCADE
      """,
      "ALTER TABLE device_keys DROP CONSTRAINT device_keys_device_fk"
    )

    # One-time / fallback keys — claimed by other devices via /keys/claim
    create table(:one_time_keys, primary_key: false) do
      add :user_id, :text, primary_key: true
      add :device_id, :text, primary_key: true
      add :algorithm, :text, primary_key: true
      add :key_id, :text, primary_key: true
      add :key_json, :map, null: false
      add :is_fallback, :boolean, null: false, default: false
      add :claimed, :boolean, null: false, default: false
    end

    # Partial index: only unclaimed keys — used by /keys/claim to pick a key
    execute(
      """
      CREATE INDEX idx_otk_unclaimed ON one_time_keys (user_id, device_id, algorithm)
        WHERE NOT claimed
      """,
      "DROP INDEX idx_otk_unclaimed"
    )

    execute(
      """
      ALTER TABLE one_time_keys
        ADD CONSTRAINT one_time_keys_device_fk
        FOREIGN KEY (user_id, device_id)
        REFERENCES devices (user_id, device_id)
        ON DELETE CASCADE
      """,
      "ALTER TABLE one_time_keys DROP CONSTRAINT one_time_keys_device_fk"
    )

    # Cross-signing keys: master / self_signing / user_signing
    create table(:cross_signing_keys, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      # 'master' | 'self_signing' | 'user_signing'
      add :key_type, :text, primary_key: true
      add :key_json, :map, null: false
    end

    create constraint(:cross_signing_keys, :valid_key_type,
             check: "key_type IN ('master', 'self_signing', 'user_signing')"
           )

    # Server-side encrypted room-key backup versions
    create table(:key_backup_versions, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :version, :text, primary_key: true
      add :algorithm, :text, null: false
      add :auth_data, :map, null: false
      add :etag, :bigint, null: false, default: 0
      add :deleted, :boolean, null: false, default: false
    end

    # Individual room keys within a backup version
    create table(:key_backup_keys, primary_key: false) do
      add :user_id, :text, primary_key: true
      add :version, :text, primary_key: true
      add :room_id, :text, primary_key: true
      add :session_id, :text, primary_key: true
      # first_message_index, forwarded_count, is_verified, session_data
      add :key_data, :map, null: false
    end

    execute(
      """
      ALTER TABLE key_backup_keys
        ADD CONSTRAINT key_backup_keys_version_fk
        FOREIGN KEY (user_id, version)
        REFERENCES key_backup_versions (user_id, version)
        ON DELETE CASCADE
      """,
      "ALTER TABLE key_backup_keys DROP CONSTRAINT key_backup_keys_version_fk"
    )

    # To-device messages: queued per device (e.g. m.room_key, key verification)
    create table(:to_device_messages) do
      add :target_user, :text, null: false
      # NULL or '*' means all devices
      add :target_device, :text
      add :sender, :text, null: false
      add :type, :text, null: false
      add :content, :map, null: false
    end

    # stream_id is the default :id bigserial primary key from create table/1
    create index(:to_device_messages, [:target_user, :target_device, :id],
             name: :idx_to_device_target
           )
  end
end
