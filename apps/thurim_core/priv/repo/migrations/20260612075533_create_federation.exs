defmodule ThurimCore.Repo.Migrations.CreateFederation do
  use Ecto.Migration

  def change do
    # Cached signing keys of remote servers (for verifying PDU signatures)
    create table(:server_signing_keys, primary_key: false) do
      add :server_name, :text, primary_key: true
      # e.g. 'ed25519:abc'
      add :key_id, :text, primary_key: true
      # base64-encoded key
      add :verify_key, :text, null: false
      add :valid_until_ts, :utc_datetime_usec
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
      add :last_successful_ts, :utc_datetime_usec
      add :retry_interval, :bigint, null: false, default: 0
      add :retry_last_ts, :utc_datetime_usec
    end
  end
end
