defmodule ThurimCore.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media, primary_key: false) do
      add :media_id, :text, primary_key: true
      # origin server (local or remote cache)
      add :server_name, :text, primary_key: true
      add :content_type, :text
      add :upload_name, :text
      add :content_length, :bigint
      add :uploaded_by, references(:users, column: :user_id, type: :text, on_delete: :nilify_all)
      # pointer to blob store / filesystem
      add :storage_path, :text, null: false
      add :sha256, :text
      add :quarantined, :boolean, null: false, default: false
      add :created_ts, :bigint, null: false
    end

    create table(:media_thumbnails, primary_key: false) do
      add :server_name, :text, primary_key: true
      add :media_id, :text, primary_key: true
      add :width, :integer, primary_key: true
      add :height, :integer, primary_key: true
      # 'crop' | 'scale'
      add :method, :text, primary_key: true
      add :content_type, :text, null: false
      add :storage_path, :text, null: false
    end

    create constraint(:media_thumbnails, :valid_method, check: "method IN ('crop', 'scale')")

    execute(
      """
      ALTER TABLE media_thumbnails
        ADD CONSTRAINT media_thumbnails_media_fk
        FOREIGN KEY (server_name, media_id)
        REFERENCES media (server_name, media_id)
        ON DELETE CASCADE
      """,
      "ALTER TABLE media_thumbnails DROP CONSTRAINT media_thumbnails_media_fk"
    )
  end
end
