defmodule ThurimCore.Repo.Migrations.CreateUserData do
  use Ecto.Migration

  def change do
    # Global account data (per user, per event type)
    create table(:account_data, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :type, :text, primary_key: true
      add :content, :map, null: false
      add :stream_id, :bigserial
    end

    # Room-scoped account data
    create table(:room_account_data, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :type, :text, primary_key: true
      add :content, :map, null: false
    end

    # Room tags (e.g. m.favourite, m.lowpriority, user-defined)
    create table(:room_tags, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :tag, :text, primary_key: true
      # order, etc.
      add :content, :map
    end

    # Read receipts and read markers (m.read, m.read.private, m.fully_read)
    create table(:receipts, primary_key: false) do
      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :user_id, :text, primary_key: true
      add :receipt_type, :text, primary_key: true
      add :thread_id, :text, primary_key: true, default: "main"
      add :event_id, :text, null: false
      # contains 'ts'
      add :data, :map
    end

    create constraint(:receipts, :valid_receipt_type,
             check: "receipt_type IN ('m.read', 'm.read.private', 'm.fully_read')"
           )

    # Presence (ephemeral but cached — clients query latest value)
    create table(:presence, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :state, :text, null: false
      add :status_msg, :text
      add :last_active_ts, :bigint
      add :currently_active, :boolean
    end

    create constraint(:presence, :valid_presence_state,
             check: "state IN ('online', 'offline', 'unavailable')"
           )
  end
end
