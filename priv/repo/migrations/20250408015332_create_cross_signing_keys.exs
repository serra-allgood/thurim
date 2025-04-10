defmodule Thurim.Repo.Migrations.CreateCrossSigningKeys do
  use Ecto.Migration

  def change do
    create table(:cross_signing_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :mx_user_id, :text, null: false
      add :keys, :jsonb, null: false
      add :usage, {:array, :text}, null: false
      add :signatures, :jsonb, null: false
    end
  end
end
