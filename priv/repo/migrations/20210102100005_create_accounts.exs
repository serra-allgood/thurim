defmodule Thurim.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :localpart, :text, primary_key: true
      add :password_hash, :text
      add :is_deactivated, :boolean, default: false, null: false

      timestamps()
    end

  end
end
