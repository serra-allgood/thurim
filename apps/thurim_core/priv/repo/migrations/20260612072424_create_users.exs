defmodule ThurimCore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      # '@alice:thurim.example.org'
      add :user_id, :text, primary_key: true
      add :localpart, :text, null: false
      add :password_hash, :binary
      add :display_name, :text
      add :avatar_url, :text
      add :is_guest, :boolean, null: false, default: false
      add :is_admin, :boolean, null: false, default: false
      add :deactivated, :boolean, null: false, default: false

      add :appservice_id,
          references(:appservices, column: :appservice_id, type: :text, on_delete: :nilify_all)

      add :created_ts, :utc_datetime_usec, null: false
    end

    create unique_index(:users, [:localpart])

    create table(:user_threepids, primary_key: false) do
      add :user_id, references(:users, column: :user_id, type: :text, on_delete: :delete_all),
        null: false

      # 'email' | 'msisdn'
      add :medium, :text, primary_key: true
      add :address, :text, primary_key: true
      add :validated_ts, :utc_datetime_usec
      add :added_ts, :utc_datetime_usec, null: false
    end

    create constraint(:user_threepids, :valid_medium, check: "medium IN ('email', 'msisdn')")

    create index(:user_threepids, [:user_id], name: :idx_threepids_user)
  end
end
