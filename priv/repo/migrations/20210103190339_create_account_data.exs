defmodule Thurim.Repo.Migrations.CreateAccountData do
  use Ecto.Migration

  def change do
    create table(:account_data, primary_key: false) do
      add :localpart, :text, null: false, primary_key: true
      add :room_id, :text, null: false, default: "", primary_key: true
      add :type, :text, null: false, primary_key: true
      add :content, :map, null: false

      timestamps()
    end

  end
end
