defmodule ThurimCore.Repo.Migrations.CreatePushFiltersSearch do
  use Ecto.Migration

  def change do
    # Pushers: registered push notification endpoints
    create table(:pushers, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :pushkey, :text, primary_key: true
      add :app_id, :text, primary_key: true
      add :kind, :text, null: false
      add :app_display_name, :text
      add :device_display_name, :text
      add :profile_tag, :text
      add :lang, :text
      # url, format for Push Gateway
      add :data, :map, null: false
    end

    create constraint(:pushers, :valid_pusher_kind, check: "kind IN ('http', 'email')")

    # Push rules — default server rules + per-user overrides
    create table(:push_rules, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :scope, :text, primary_key: true, default: "global"
      add :kind, :text, primary_key: true
      add :rule_id, :text, primary_key: true
      add :priority, :integer, null: false
      add :conditions, :map
      add :actions, :map, null: false
      add :enabled, :boolean, null: false, default: true
    end

    create constraint(:push_rules, :valid_push_rule_kind,
             check: "kind IN ('override', 'content', 'room', 'sender', 'underride')"
           )

    # Client-side event filters (/filter)
    create table(:filters, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :filter_id, :text, primary_key: true
      add :definition, :map, null: false
    end

    # Full-text search index over message body / room name / topic (/search)
    create table(:event_search, primary_key: false) do
      add :event_id, references(:events, column: :event_id, type: :text, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :room_id, :text, null: false
      add :sender, :text, null: false
      # 'content.body' | 'content.name' | 'content.topic'
      add :key, :text, null: false
      add :vector, :tsvector, null: false
    end

    execute(
      "CREATE INDEX idx_event_search_gin ON event_search USING gin (vector)",
      "DROP INDEX idx_event_search_gin"
    )
  end
end
