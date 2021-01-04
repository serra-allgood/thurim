defmodule Thurim.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :localpart, :text, primary_key: true
      add :display_name, :text
      add :avatar_url, :text

      timestamps()
    end

  end
end
