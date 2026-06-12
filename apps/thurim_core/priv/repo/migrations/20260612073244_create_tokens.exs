defmodule ThurimCore.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :token, :text, primary_key: true

      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        null: false

      add :device_id,
          references(:devices,
            type: :text,
            column: :device_id,
            with: [user_id: :user_id],
            on_delete: :delete_all
          ),
          null: false

      # Self-referencing rotation chain — deferred to avoid ordering issues
      add :next_token, :text
      add :expires_ts, :utc_datetime_usec
      add :created_ts, :utc_datetime_usec, null: false
    end

    create unique_index(:refresh_tokens, :next_token)

    # Add the self-referencing FK after the table exists
    alter table(:refresh_tokens) do
      modify :next_token,
             references(:refresh_tokens,
               column: :next_token,
               type: :text,
               on_delete: :nilify_all
             ),
             from: :text
    end

    create table(:access_tokens, primary_key: false) do
      add :token, :text, primary_key: true

      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        null: false

      add :device_id, :text

      add :refresh_token,
          references(:refresh_tokens, type: :text, column: :token, on_delete: :nilify_all)

      add :valid_until_ts, :utc_datetime_usec
      add :created_ts, :utc_datetime_usec, null: false
    end

    create index(:access_tokens, [:user_id], name: :idx_access_tokens_user)

    create table(:login_tokens, primary_key: false) do
      add :token, :text, primary_key: true

      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        null: false

      add :expires_ts, :utc_datetime_usec, null: false
    end
  end
end
