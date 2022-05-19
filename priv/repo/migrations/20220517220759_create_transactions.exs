defmodule Thurim.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :localpart, :text, null: false, primary_key: true
      add :device_id, :text, null: false, primary_key: true
      add :transaction_id, :text, null: false, primary_key: true
      add :event_id, :text, null: false

      timestamps()
    end
  end
end
