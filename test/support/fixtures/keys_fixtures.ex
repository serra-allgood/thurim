defmodule Thurim.KeysFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Thurim.Keys` context.
  """

  @doc """
  Generate a key.
  """
  def key_fixture(attrs \\ %{}) do
    {:ok, key} =
      attrs
      |> Enum.into(%{

      })
      |> Thurim.Keys.create_key()

    key
  end
end
