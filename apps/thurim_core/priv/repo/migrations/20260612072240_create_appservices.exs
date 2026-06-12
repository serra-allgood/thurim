defmodule ThurimCore.Repo.Migrations.CreateAppservices do
  use Ecto.Migration

  def change do
    create table(:appservices, primary_key: false) do
      add :appservice_id, :text, primary_key: true
      add :homeserver_token, :text, null: false
      add :appservice_token, :text, null: false
      add :url, :text
      add :sender_localpart, :text, null: false
      add :rate_limited, :boolean, null: false, default: true
      add :protocols, {:array, :text}
    end

    create table(:appservice_namespaces, primary_key: false) do
      add :appservice_id,
          references(:appservices, column: :appservice_id, type: :text, on_delete: :delete_all),
          primary_key: true

      # 'users' | 'aliases' | 'rooms'
      add :namespace_type, :text, primary_key: true
      add :regex, :text, primary_key: true
      add :exclusive, :boolean, null: false, default: false
    end

    create constraint(:appservice_namespaces, :valid_namespace_type,
             check: "namespace_type IN ('users', 'aliases', 'rooms')"
           )

    create table(:appservice_txns, primary_key: false) do
      add :appservice_id,
          references(:appservices, column: :appservice_id, type: :text, on_delete: :delete_all),
          primary_key: true

      add :txn_id, :text, primary_key: true
    end
  end
end
