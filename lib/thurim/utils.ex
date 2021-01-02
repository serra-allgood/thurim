defmodule Thurim.Utils do
  def crypto_random_string(length \\ 30) do
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
