defmodule Thurim.Repo.Migrations.CreateDeviceAlgorithms do
  use Ecto.Migration

  def change do
    create table(:device_algorithms, primary_key: false) do
      add :device_id, :text, primary_key: true
      add :supported_algorithms, {:array, :string}, null: false

      timestamps()
    end
  end
end
