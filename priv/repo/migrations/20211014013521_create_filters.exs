defmodule Thurim.Repo.Migrations.CreateFilters do
  use Ecto.Migration

  def change do
    create table(:filters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filter, :map
      add :localpart, :string, primary_key: true

      timestamps()
    end

    create index(:filters, :localpart)
  end
end
