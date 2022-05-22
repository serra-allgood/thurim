defmodule Thurim.Federation.KeyServer do
  use GenServer

  @algo "ed25519"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {public_key, private_key} = generate_keypair()
    version = generate_random_version()

    state =
      %{
        "old_verify_keys" => %{},
        "verify_keys" => %{},
        "valid_until_ts" => week_from_now(),
        "private_keys" => %{"#{@algo}:#{version}" => private_key}
      }
      |> Map.update!("verify_keys", fn verify_keys ->
        Map.put(verify_keys, "#{@algo}:#{version}", public_key |> Base.encode64(padding: false))
      end)

    {:ok, state}
  end

  def get_keys do
    GenServer.call(__MODULE__, {:get_keys})
  end

  def sign(json) do
    GenServer.call(__MODULE__, {:sign, json})
  end

  def handle_call({:sign, json}, _from, state) do
    {identifier, private_key} =
      state["private_keys"]
      |> Map.to_list()
      |> List.first()

    reply = %{
      identifier =>
        :crypto.sign(:eddsa, :sha512, json, [private_key, :ed25519])
        |> Base.encode64(padding: false)
    }

    {:reply, reply, state}
  end

  def handle_call({:get_keys}, _from, state) do
    new_state =
      if now() >= state["valid_until_ts"] do
        {public_key, private_key} = generate_keypair()
        version = generate_random_version()

        Map.put(state, "valid_until_ts", week_from_now())
        |> Map.update!("old_verify_keys", fn old_verify_keys ->
          Map.keys(state["verify_keys"])
          |> Enum.reduce(old_verify_keys, fn key_version, old_keys ->
            Map.put(old_keys, key_version, state["verify_keys"][key_version])
          end)
        end)
        |> Map.update!("verify_keys", fn verify_keys ->
          old_key_versions = Map.keys(verify_keys)

          Map.drop(verify_keys, old_key_versions)
          |> Map.put("#{@algo}:#{version}", public_key |> Base.url_encode64(padding: false))
        end)
        |> Map.update!("private_keys", fn private_keys ->
          Map.put(private_keys, "#{@algo}:#{version}", private_key)
        end)
      else
        state
      end

    {:reply, Map.drop(state, ["private_keys"]), new_state}
  end

  defp week_from_now do
    Timex.now() |> DateTime.add(84600 * 7) |> DateTime.to_unix(:millisecond)
  end

  defp now do
    Timex.now() |> DateTime.to_unix(:millisecond)
  end

  defp generate_random_version do
    :crypto.strong_rand_bytes(8)
    |> Base.url_encode64(padding: false, ignore: :whitespace)
    |> binary_part(0, 8)
  end

  defp generate_keypair do
    :crypto.generate_key(:eddsa, :ed25519)
  end
end
