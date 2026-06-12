defmodule ThurimCore.Repo.Migrations.CreateState do
  use Ecto.Migration

  def change do
    # Resolved current state: one row per (room, type, state_key) after state-resolution
    create table(:current_state_events, primary_key: false) do
      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :type, :text, primary_key: true
      add :state_key, :text, primary_key: true

      add :event_id, references(:events, column: :event_id, type: :text, on_delete: :delete_all),
        null: false
    end

    # Denormalized membership view — derived from m.room.member state events
    create table(:room_memberships, primary_key: false) do
      add :room_id, references(:rooms, column: :room_id, type: :text, on_delete: :delete_all),
        primary_key: true

      add :user_id, :text, primary_key: true
      add :membership, :text, null: false

      add :event_id, references(:events, column: :event_id, type: :text, on_delete: :delete_all),
        null: false

      # add :display_name, :text
      # add :avatar_url, :text
    end

    create constraint(:room_memberships, :valid_membership,
             check: "membership IN ('invite', 'join', 'leave', 'ban', 'knock')"
           )

    create index(:room_memberships, [:user_id, :membership], name: :idx_memberships_user)
    create index(:room_memberships, [:room_id, :membership], name: :idx_memberships_room)
  end
end
