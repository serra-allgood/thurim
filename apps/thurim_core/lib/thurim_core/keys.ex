defmodule ThurimCore.Keys do
  import Ecto.Query, warn: false
  alias ThurimCore.{Keys.ServerSigningKey, Repo}

  def all_server_signing_keys do
    Repo.all(ServerSigningKey)
  end

  def generate_signing_key(version \\ random_signing_key_version()) do
    {pub, priv} = :crypto.generate_key(:eddsa, :ed25519)

    %ServerSigningKey{
      key_id: "ed25519:#{version}",
      version: version,
      algorithm: "ed25519",
      private_key: priv,
      public_key: pub,
      public_b64: Base.url_encode64(pub, padding: false)
    }
  end

  def get_active_server_signing_key do
    from(k in ServerSigningKey, where: not k.is_expired, limit: 1)
    |> Repo.one()
  end

  defp random_signing_key_version do
    :crypto.strong_rand_bytes(6)
    |> Base.url_encode64(padding: false)
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end

  def retire_signing_key do
    Repo.transact(fn ->
      from(k in ServerSigningKey, where: not k.is_expired)
      |> Repo.update_all(set: [is_expired: true, private_key: nil])

      key =
        generate_signing_key()
        |> Repo.insert!()

      {:ok, key}
    end)
  end
end
