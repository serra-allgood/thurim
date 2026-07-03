defmodule ThurimCore.Repo.Migrations.CreateFederation do
  use Ecto.Migration

  def change do
    create table(:server_signing_keys, primary_key: false) do
      # "ed25519:abc123"
      add :key_id, :text, primary_key: true
      add :algorithm, :text, null: false, default: "ed25519"
      add :version, :text, null: false
      # raw 32-byte ed25519 public key
      add :public_key, :bytea, null: false
      # NULL for old/retired keys (secret discarded)
      add :private_key, :bytea
      # unpadded base64, ready to publish
      add :public_b64, :text, null: false
      add :is_expired, :boolean, null: false, default: false
      add :valid_until_ts, :bigint, null: false
      add :created_ts, :bigint, null: false
    end

    # Only one active key per algorithm at a time is typical, but the spec allows many.
    create index(:server_signing_keys, [:valid_until_ts])

    # Cached signing keys of remote servers (for verifying PDU signatures)
    create table(:remote_server_signing_keys, primary_key: false) do
      add :server_name, :text, primary_key: true
      # e.g. 'ed25519:abc'
      add :key_id, :text, primary_key: true
      # base64-encoded key
      add :verify_key, :text, null: false
      add :valid_until_ts, :bigint
    end

    # Outbound federation queue: PDUs and EDUs per destination
    create table(:federation_outbound, primary_key: false) do
      add :destination, :text, primary_key: true
      add :stream_id, :bigserial, primary_key: true
      # references events.event_id (not FK — may be outlier)
      add :pdu_event_id, :text
      add :edu_json, :map
    end

    # Per-destination delivery state and retry backoff tracking
    create table(:federation_destinations, primary_key: false) do
      add :destination, :text, primary_key: true
      add :last_successful_ts, :bigint
      add :retry_interval, :bigint, null: false, default: 0
      add :retry_last_ts, :bigint
    end
  end
end
