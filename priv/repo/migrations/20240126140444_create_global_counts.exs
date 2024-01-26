defmodule Thurim.Repo.Migrations.CreateGlobalCounts do
  use Ecto.Migration

  def change do
    create table(:global_counts, primary_key: false) do
      add :name, :string, primary_key: true
      add :count, :bigint, null: false
    end
  end
end
