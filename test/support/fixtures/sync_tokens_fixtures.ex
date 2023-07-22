defmodule Thurim.SyncTokensFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Thurim.SyncTokens` context.
  """

  @doc """
  Generate a sync_token.
  """
  def sync_token_fixture(attrs \\ %{}) do
    {:ok, sync_token} =
      attrs
      |> Enum.into(%{})
      |> Thurim.SyncTokens.create_sync_token()

    sync_token
  end
end
